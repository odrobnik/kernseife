//
//  WebService.m
//  SOAP
//
//  Created by Oliver on 16.10.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "WebService.h"
#import "XMLdocument.h"
#import "NSString+Helpers.h"

@implementation WebService

#pragma mark Conversions

- (NSString *)conversionFromNSStringToType:(NSString *)otherType variable:(NSString *)variable
{
	if ([otherType isEqualToString:@"NSString *"])
	{
		// no conversion necessary
		return variable;
	}
	else if ([otherType isEqualToString:@"NSInteger"])
	{
		// convert to int
		return [NSString stringWithFormat:@"[%@ intValue]", variable];
	}
	else if ([otherType isEqualToString:@"double"])
	{
		// convert to double
		return [NSString stringWithFormat:@"[%@ doubleValue]", variable];
	}
	else if ([otherType isEqualToString:@"NSDate *"])
	{
		// convert to NSDate
		return [NSString stringWithFormat:@"[%@ dateFromISO8601]", variable];
	}
	
	return nil;
}

- (NSString *)conversionFromTypeToNSString:(NSString *)otherType variable:(NSString *)variable
{
	if ([otherType isEqualToString:@"NSString *"])
	{
		// no conversion necessary
		return variable;
	}
	else if ([otherType isEqualToString:@"NSInteger"])
	{
		// convert to int
		return [NSString stringWithFormat:@"[NSString stringWithFormat:@\"%%d\", %@]", variable];
	}
	else if ([otherType isEqualToString:@"double"])
	{
		// convert to double
		return [NSString stringWithFormat:@"[NSString stringWithFormat:@\"%%f\", %@]", variable];
	}
	else if ([otherType isEqualToString:@"NSDate *"])
	{
		// convert to NSDate
		return [NSString stringWithFormat:@"[%@ ISO8601string]", variable];
	}
	
	return nil;
}

- (BOOL) isBoolStringYES:(NSString *)string
{
	if ([[string lowercaseString] isEqualToString:@"false"] ||
		[[string lowercaseString] isEqualToString:@"0"])
	{
		return NO;
	}
	else
	{
		return YES;
	}
}

#pragma mark Requests

- (NSURLRequest *) makeGETRequestWithLocation:(NSString *)url Parameters:(NSDictionary *)parameters
{
	NSMutableString *query = [NSMutableString string];
	
	for (NSString *oneKey in [parameters allKeys])
	{
		if ([query length])
		{
			[query appendString:@"&"];
		}
		else
		{
			[query appendString:@"?"];
		}

		
		[query appendFormat:@"%@=%@", oneKey, [[parameters objectForKey:oneKey] stringByUrlEncoding]];	
	}
	
	url = [url stringByAppendingString:query];

	return [[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]] autorelease];
}


- (NSURLRequest *) makePOSTRequestWithLocation:(NSString *)url Parameters:(NSDictionary *)parameters
{
	NSMutableString *query = [NSMutableString string];
	
	for (NSString *oneKey in [parameters allKeys])
	{
		if ([query length])
		{
			[query appendString:@"&"];
		}
		
		
		[query appendFormat:@"%@=%@", oneKey, [[parameters objectForKey:oneKey] stringByUrlEncoding]];	
	}
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]] autorelease];
	
	[request setHTTPMethod:@"POST"];
	[request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	
	// make body
	NSData *postBody = [NSData dataWithData:[query dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody:postBody];
	
	return request;
}


- (NSURLRequest *) makeSOAPRequestWithLocation:(NSString *)url Parameters:(NSArray *)parameters Operation:(NSString *)operation Namespace:(NSString *)namespace Action:(NSString *)action SOAPVersion:(SOAPVersion)soapVersion;
{
	
	NSMutableString *envelope = [NSMutableString string];
	
	[envelope appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"];
	
	switch (soapVersion) {
		case SOAPVersion1_0:
			[envelope appendString:@"<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n"];
			break;
		case SOAPVersion1_2:
			[envelope appendString:@"<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\">\n"];
			break;
	}
	[envelope appendString:@"<soap:Body>\n"];

	[envelope appendFormat:@"<%@ xmlns=\"%@\">\n", operation, namespace];

	
	for (NSDictionary *oneParameter in parameters)
	{
		NSObject *value = [oneParameter objectForKey:@"value"];
		
		if ([[value class] isKindOfClass:[NSString class]] ||
			[[value class] isKindOfClass:[NSNumber class]])
		{
			[envelope appendFormat:@"<%@>%@</%@>\n", [oneParameter objectForKey:@"name"], [[[oneParameter objectForKey:@"value"] description] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [oneParameter objectForKey:@"name"]];
		}
		else {
			[envelope appendFormat:@"<%@>%@</%@>\n", [oneParameter objectForKey:@"name"], [[[oneParameter objectForKey:@"value"] description] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [oneParameter objectForKey:@"name"]];
		}
	}			
	
	[envelope appendFormat:@"</%@>\n", operation];
	[envelope appendString:@"</soap:Body>\n"];
	[envelope appendString:@"</soap:Envelope>\n"];

	//NSLog(@"%@", parameters);
	//NSLog(@"%@", envelope);

	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]] autorelease];
	
	[request setHTTPMethod:@"POST"];
	[request addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	[request addValue:action forHTTPHeaderField:@"SOAPAction"];
	
	// make body
	NSData *postBody = [NSData dataWithData:[envelope dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody:postBody];
	
	return request;
}

- (NSString *) returnValueFromSOAPResponse:(XMLdocument *)envelope
{
	XMLelement *body = [envelope.documentRoot getNamedChild:@"Body"];
	XMLelement *response = [body.children lastObject];  // there should be only one

	if (response.children)
	{	
		XMLelement *retChild = [response.children lastObject];
		
		return retChild.text;
	}
	else 
	{
		return nil;
	}
}

- (id) returnComplexTypeFromSOAPResponse:(XMLdocument *)envelope asClass:(Class)retClass
{
	// create a new instance of expected class
	
	id newObject = [[[retClass alloc] init] autorelease];
	
	XMLelement *body = [envelope.documentRoot getNamedChild:@"Body"];
	XMLelement *response = [body.children lastObject];  // there should be only one

	XMLelement *result = [response.children lastObject];  // there should be only one

	
	for (XMLelement *oneChild in result.children)
	{
		// this seems to work for scalars as well as strings without problem
		[newObject setValue:oneChild.text forKey:oneChild.name];
	}
	
	return newObject;
}



@end