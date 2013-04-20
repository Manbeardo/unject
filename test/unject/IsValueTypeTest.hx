package unject;

import haxe.rtti.Infos;

import massive.munit.Assert;

import unject.type.URtti;

class IsValueTypeTest
{
	public function new() {}

	@Test
	public function testIsValueType()
	{
		Assert.isFalse(URtti.isValueType(IsValueTypeTest));
		Assert.isFalse(URtti.isValueType(Date));

		Assert.isTrue(URtti.isValueType(Int));
		Assert.isTrue(URtti.isValueType(Float));
		Assert.isTrue(URtti.isValueType(String));
		Assert.isTrue(URtti.isValueType(Bool));

		Assert.isFalse(URtti.isValueType(new IsValueTypeTest()));

		Assert.isTrue(URtti.isValueType("abc"));
		Assert.isTrue(URtti.isValueType(123));
		Assert.isTrue(URtti.isValueType(123.45));
		Assert.isTrue(URtti.isValueType(true));
	}
}
