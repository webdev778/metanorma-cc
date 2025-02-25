require "asciidoctor"
require "isodoc/cc/html_convert"
require "isodoc/cc/word_convert"
require "isodoc/cc/presentation_xml_convert"
require "metanorma/cc"
require "asciidoctor/standoc/converter"
require "asciidoctor/generic/converter"
require_relative "validate_section"

module Asciidoctor
  module CC
    class Converter < Asciidoctor::Generic::Converter
      XML_ROOT_TAG = "csd-standard".freeze
      XML_NAMESPACE = "https://www.metanorma.org/ns/csd".freeze

      register_for "cc"

      def configuration
        Metanorma::CC.configuration
      end

      def metadata_committee(node, xml)
        return unless node.attr("technical-committee")

        xml.editorialgroup do |a|
          a.committee node.attr("technical-committee"),
                      **attr_code(type: node.attr("technical-committee-type"))
          i = 2
          while node.attr("technical-committee_#{i}")
            a.committee node.attr("technical-committee_#{i}"),
                        **attr_code(type: node.attr("technical-committee-type_#{i}"))
            i += 1
          end
        end
      end

      def outputs(node, ret)
        File.open("#{@filename}.xml", "w:UTF-8") { |f| f.write(ret) }
        presentation_xml_converter(node).convert("#{@filename}.xml")
        html_converter(node).convert("#{@filename}.presentation.xml",
                                     nil, false, "#{@filename}.html")
        doc_converter(node).convert("#{@filename}.presentation.xml",
                                    nil, false, "#{@filename}.doc")
        pdf_converter(node)&.convert("#{@filename}.presentation.xml",
                                     nil, false, "#{@filename}.pdf")
      end

      def html_converter(node)
        IsoDoc::CC::HtmlConvert.new(html_extract_attributes(node))
      end

      def pdf_converter(node)
        return if node.attr("no-pdf")

        IsoDoc::CC::PdfConvert.new(pdf_extract_attributes(node))
      end

      def doc_converter(node)
        IsoDoc::CC::WordConvert.new(doc_extract_attributes(node))
      end

      def presentation_xml_converter(node)
        IsoDoc::CC::PresentationXMLConvert.new(doc_extract_attributes(node))
      end
    end
  end
end
