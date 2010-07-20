package com.gerixsoft.css2xml;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.sax.SAXTransformerFactory;
import javax.xml.transform.sax.TransformerHandler;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import javax.xml.validation.Validator;

import org.xml.sax.ErrorHandler;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;
import org.xml.sax.helpers.AttributesImpl;

public class CssToXml {

	public static void main(String[] args) throws ParserConfigurationException, IOException, SAXException, TransformerException {
		if (args.length != 2) {
			System.err.println("usage: <css-file> <xml-file>");
			System.exit(-1);
		}
		css2xml(new File(args[0]), new File(args[1]));
		System.out.println("ok");
	}

	public static void css2xml(File inputFile, File outputFile) throws ParserConfigurationException, IOException, SAXException, TransformerException {
		SAXTransformerFactory handlerFactory = (SAXTransformerFactory) SAXTransformerFactory.newInstance();
		TransformerHandler handler = handlerFactory.newTransformerHandler(new StreamSource(CssToXml.class.getResource("css2xml.xsl").toString()));
		handler.getTransformer().setOutputProperty("indent", "yes");
		handler.setResult(new StreamResult(outputFile));
		handler.startDocument();
		handler.startElement("", "css", "css", new AttributesImpl());
		{
			char[] text;
			{
				InputStream inputStream = new FileInputStream(inputFile);
				try {
					ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
					try {
						byte[] buffer = new byte[65535];
						int bytesRead;
						while ((bytesRead = inputStream.read(buffer)) > 0) {
							outputStream.write(buffer, 0, bytesRead);
						}
						text = outputStream.toString().toCharArray();
					} finally {
						outputStream.close();
					}
				} finally {
					inputStream.close();
				}
			}
			handler.characters(text, 0, text.length);
		}
		handler.endElement("", "css", "css");
		handler.endDocument();

		SchemaFactory factory = SchemaFactory.newInstance("http://www.w3.org/2001/XMLSchema");
		Schema schema = factory.newSchema(new StreamSource(CssToXml.class.getResourceAsStream("css.xsd")));
		Validator validator = schema.newValidator();
		validator.setErrorHandler(new ErrorHandler() {
			@Override
			public void warning(SAXParseException exception) throws SAXException {
				log("warning", exception);
			}

			@Override
			public void fatalError(SAXParseException exception) throws SAXException {
				log("fatal error", exception);
			}

			@Override
			public void error(SAXParseException exception) throws SAXException {
				log("error", exception);
			}

			public void log(String type, SAXParseException exception) {
				System.err.println(type + " at line: " + exception.getLineNumber() + " col:" + exception.getColumnNumber() + " message: "
						+ exception.getMessage());
			}
		});
		validator.validate(new StreamSource(outputFile));
	}

}
