# frozen_string_literal: true

describe QA::Factory::Base do
  include Support::StubENV

  let(:factory) { spy('factory') }
  let(:location) { 'http://location' }

  shared_context 'fabrication context' do
    subject do
      Class.new(described_class) do
        def self.name
          'MyFactory'
        end
      end
    end

    before do
      allow(subject).to receive(:current_url).and_return(location)
      allow(subject).to receive(:new).and_return(factory)
    end
  end

  shared_examples 'fabrication method' do |fabrication_method_called, actual_fabrication_method = nil|
    let(:fabrication_method_used) { actual_fabrication_method || fabrication_method_called }

    it 'yields factory before calling factory method' do
      expect(factory).to receive(:something!).ordered
      expect(factory).to receive(fabrication_method_used).ordered.and_return(location)

      subject.public_send(fabrication_method_called, factory: factory) do |factory|
        factory.something!
      end
    end

    it 'does not log the factory and build method when QA_DEBUG=false' do
      stub_env('QA_DEBUG', 'false')
      expect(factory).to receive(fabrication_method_used).and_return(location)

      expect { subject.public_send(fabrication_method_called, 'something', factory: factory) }
        .not_to output.to_stdout
    end
  end

  describe '.fabricate!' do
    context 'when factory does not support fabrication via the API' do
      before do
        expect(described_class).to receive(:fabricate_via_api!).and_raise(NotImplementedError)
      end

      it 'calls .fabricate_via_browser_ui!' do
        expect(described_class).to receive(:fabricate_via_browser_ui!)

        described_class.fabricate!
      end
    end

    context 'when factory supports fabrication via the API' do
      it 'calls .fabricate_via_browser_ui!' do
        expect(described_class).to receive(:fabricate_via_api!)

        described_class.fabricate!
      end
    end
  end

  describe '.fabricate_via_api!' do
    include_context 'fabrication context'

    it_behaves_like 'fabrication method', :fabricate_via_api!

    it 'instantiates the factory, calls factory method returns the resource' do
      expect(factory).to receive(:fabricate_via_api!).and_return(location)

      result = subject.fabricate_via_api!(factory: factory, parents: [])

      expect(result).to eq(factory)
    end

    it 'logs the factory and build method when QA_DEBUG=true' do
      stub_env('QA_DEBUG', 'true')
      expect(factory).to receive(:fabricate_via_api!).and_return(location)

      expect { subject.fabricate_via_api!('something', factory: factory, parents: []) }
        .to output(/==> Built a MyFactory via api in [\d\.\-e]+ seconds+/)
        .to_stdout
    end
  end

  describe '.fabricate_via_browser_ui!' do
    include_context 'fabrication context'

    it_behaves_like 'fabrication method', :fabricate_via_browser_ui!, :fabricate!

    it 'instantiates the factory and calls factory method' do
      subject.fabricate_via_browser_ui!('something', factory: factory, parents: [])

      expect(factory).to have_received(:fabricate!).with('something')
    end

    it 'returns fabrication resource' do
      result = subject.fabricate_via_browser_ui!('something', factory: factory, parents: [])

      expect(result).to eq(factory)
    end

    it 'logs the factory and build method when QA_DEBUG=true' do
      stub_env('QA_DEBUG', 'true')

      expect { subject.fabricate_via_browser_ui!('something', factory: factory, parents: []) }
        .to output(/==> Built a MyFactory via browser_ui in [\d\.\-e]+ seconds+/)
        .to_stdout
    end
  end

  shared_context 'simple factory' do
    subject do
      Class.new(QA::Factory::Base) do
        attribute :test do
          'block'
        end

        attribute :no_block

        def fabricate!
          'any'
        end

        def self.current_url
          'http://stub'
        end
      end
    end

    let(:factory) { subject.new }
  end

  describe '.attribute' do
    include_context 'simple factory'

    it 'appends new attribute' do
      expect(subject.attributes_names).to eq([:no_block, :test, :web_url])
    end

    context 'when the attribute is populated via a block' do
      it 'returns value from the block' do
        result = subject.fabricate!(factory: factory)

        expect(result).to be_a(described_class)
        expect(result.test).to eq('block')
      end
    end

    context 'when the attribute is populated via the api' do
      let(:api_resource) { { no_block: 'api' } }

      before do
        expect(factory).to receive(:api_resource).and_return(api_resource)
      end

      it 'returns value from api' do
        result = subject.fabricate!(factory: factory)

        expect(result).to be_a(described_class)
        expect(result.no_block).to eq('api')
      end

      context 'when the attribute also has a block' do
        let(:api_resource) { { test: 'api_with_block' } }

        before do
          allow(QA::Runtime::Logger).to receive(:info)
        end

        it 'returns value from api and emits an INFO log entry' do
          result = subject.fabricate!(factory: factory)

          expect(result).to be_a(described_class)
          expect(result.test).to eq('api_with_block')
          expect(QA::Runtime::Logger)
            .to have_received(:info).with(/api_with_block/)
        end
      end
    end

    context 'when the attribute is populated via direct assignment' do
      before do
        factory.test = 'value'
      end

      it 'returns value from the assignment' do
        result = subject.fabricate!(factory: factory)

        expect(result).to be_a(described_class)
        expect(result.test).to eq('value')
      end

      context 'when the api also has such response' do
        before do
          allow(factory).to receive(:api_resource).and_return({ test: 'api' })
        end

        it 'returns value from the assignment' do
          result = subject.fabricate!(factory: factory)

          expect(result).to be_a(described_class)
          expect(result.test).to eq('value')
        end
      end
    end

    context 'when the attribute has no value' do
      it 'raises an error because no values could be found' do
        result = subject.fabricate!(factory: factory)

        expect { result.no_block }
          .to raise_error(described_class::NoValueError, "No value was computed for no_block of #{factory.class.name}.")
      end
    end
  end

  describe '#web_url' do
    include_context 'simple factory'

    it 'sets #web_url to #current_url after fabrication' do
      subject.fabricate!(factory: factory)

      expect(factory.web_url).to eq(subject.current_url)
    end
  end

  describe '#visit!' do
    include_context 'simple factory'

    before do
      allow(factory).to receive(:visit)
    end

    it 'calls #visit with the underlying #web_url' do
      factory.web_url = subject.current_url
      factory.visit!

      expect(factory).to have_received(:visit).with(subject.current_url)
    end
  end
end
