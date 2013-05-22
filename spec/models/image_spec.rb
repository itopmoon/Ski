require 'spec_helper'

describe Image do
  it { should respond_to(:source_url) }

  describe "#determine_filename" do
    context "when file data is supplied" do
      let(:file_data) { mock(Object).as_null_object }

      context "when file data responds to original_filename" do
        it "sets its filename to the image.<ext> where <ext> is the lowercased uploaded file extension" do
          file_data.stub(:original_filename).and_return('apple.banana.JPEG')
          i = Image.new
          i.image = file_data
          expect(i.determine_filename).to eq('image.jpeg')
          expect(i.filename).to eq('image.jpeg')
        end
      end

      context "when file data doesn't respond to original_filename" do
        it "sets its filename to the image.jpg" do
          file_data.stub(:respond_to?).with('original_filename').and_return(false)
          i = Image.new
          i.image = file_data
          expect(i.determine_filename).to eq('image.jpg')
          expect(i.filename).to eq('image.jpg')
        end
      end
    end

    context "when source_url is set instead of file data" do
      it "sets its filename to image.jpg" do
        i = Image.new
        i.source_url = 'http://www.example.org/image.png'
        expect(i.determine_filename).to eq('image.jpg')
        expect(i.filename).to eq('image.jpg')
      end
    end

    context "when neither file data nor source_url supplied" do
      it "raises an exception" do
        i = Image.new
        expect {i.determine_filename}.to raise_error(RuntimeError)
      end
    end
  end

  describe "#url" do
    it "downloads the image from the source URL if needed" do
      i = Image.new
      i.should_receive(:download_from_source_if_needed)
      i.url
    end
  end

  describe "#sized_url" do
    it "downloads the image from the source URL if needed" do
      i = Image.new
      i.stub(:filename).and_return('image.jpg')
      i.should_receive(:download_from_source_if_needed)
      i.sized_url(100, :longest_side)
    end
  end

  describe "#download_from_source_if_needed" do
    context "when the image does not exist and source_url is set" do
      it "downloads the image from source" do
        FileTest.stub(:exists?).and_return(false)
        i = Image.new
        i.source_url = 'http://example.org'
        i.should_receive(:download_from_source)
        i.download_from_source_if_needed
      end
    end

    context "when the image exists" do
      it "does nothing" do
        FileTest.stub(:exists?).and_return(true)
        i = Image.new
        i.should_not_receive(:download_from_source)
        i.download_from_source_if_needed
      end
    end

    context "when the source_url is not set" do
      it "does nothing" do
        i = Image.new
        i.should_not_receive(:download_from_source)
        i.download_from_source_if_needed
      end
    end
  end

  describe "#needs_downloading?" do
    it "returns true if the file doesn't exist and the source URL is not blank" do
      i = Image.new
      i.source_url = 'http://www.example.org/image.jpeg'
      FileTest.stub(:exists?).and_return(false)
      expect(i.needs_downloading?).to be_true
    end

    it "returns false if the file exists" do
      i = Image.new
      i.source_url = 'http://www.example.org/image.jpeg'
      FileTest.stub(:exists?).and_return(true)
      expect(i.needs_downloading?).to be_false
    end

    it "returns false if the source URL is blank" do
      i = Image.new
      FileTest.stub(:exists?).and_return(true)
      expect(i.needs_downloading?).to be_false
    end
  end
end
