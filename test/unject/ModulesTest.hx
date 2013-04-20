package unject;

import haxe.rtti.Infos;

import massive.munit.Assert;

import unject.type.URtti;

class ModulesTest
{
	var kernel:IKernel;

	private inline function assertRaises(test:Void->Void, ?type:Class<Dynamic>)
	{
		try
		{
			test();
			Assert.fail("Should have thrown" + (type == null ? "" : " a " + type));
		}
		catch (e:Dynamic)
		{
			if (type != null)
			{
				Assert.isType(e, type);
			}
		}
	}

	@Before
	public function setup()
	{
		kernel = new StandardKernel([new TestModule()]);
	}

	@Test
	public function testModuleLoad()
	{
		var samurai = kernel.get(Samurai);

		Assert.areEqual("Chopped the evildoers in half.", samurai.attack("the evildoers"));
	}

	@Test
	public function testNoInfos()
	{
		var k = this.kernel;
		k.bind(NoInfos, NoInfos);

		// Neko is behaving best and won't accept a class without a constructor.
		#if neko
		assertRaises(function() { trace(k.get(NoInfos)); }, String);
		#else
		Assert.isTrue(Std.is(k.get(NoInfos), NoInfos));
		#end
	}

	@Test
	public function testNoConstructor()
	{
		var k = this.kernel;

		k.bind(NoConstructor, NoConstructor);
		assertRaises(function() { k.get(NoConstructor); }, String);
	}

	@Test
	public function testNoMappingNoConstructor()
	{
		var kernel = this.kernel;

		Assert.areEqual("Chopped all enemies in half.", kernel.get(Sword).hit("all enemies"));
	}

	@Test
	public function testNoMappingInConstructor()
	{
		var k = this.kernel;

		#if !(js || flash8)
		assertRaises(function() { k.get(Japan); }, String);
		#else
		// Javascript manages to resolve this because of its default values.
		Assert.isTrue(Std.is(k.get(Japan), Japan));
		Assert.isTrue(Std.is(k.get(Japan).shogun, IShogun));
		#end
	}

	@Test
	public function testMappingToSelf()
	{
		var ninja = kernel.get(Ninja);

		Assert.areEqual("Throws a fireball into the air.", ninja.doMagic());
		Assert.areEqual("Chopped the ronin in half. (Sneaky)", ninja.sneakAttack("the ronin"));
	}

	@Test
	public function testWithParameter()
	{
		var katana = kernel.get(Katana);
		Assert.areEqual(100, katana.sharpness);
		Assert.areEqual(true, katana.used);
	}

	@Test
	public function testWithUnBoundParameter()
	{
		var k = this.kernel;
		assertRaises(function() { trace(k.get(Wakizachi).sharpness); }, String);
	}

	@Test
	public function testGetInterface()
	{
		// This also tests autobinding since Fireball has a parameterless constructor.
		var magic = kernel.get(IMagic);
		Assert.isTrue(Std.is(magic, Fireball));
	}

	@Test
	public function testSingletonScope()
	{
		var n1 = kernel.get(Ninja);
		var n2 = kernel.get(Ninja);

		Assert.areNotEqual(n1, n2);
		Assert.areEqual(n1.magic, n2.magic);
	}

	@Test
	public function testAutoBindingFailing()
	{
		var k = this.kernel;
		k.bind(IWeapon, MagicSword);

		// Flash and js manages to resolve this because of their default value handling.
		// Other platforms will complain on not enough constructor parameters.
		#if (js || flash)
		Assert.isType(k.get(IWeapon), MagicSword);
		Assert.isType(k.get(MagicSword), MagicSword);
		#else
		assertRaises(function() { k.get(IWeapon); }, String);
		assertRaises(function() { k.get(MagicSword); }, String);
		#end
	}

	@Test
	public function testBindToInstance()
	{
		var k = this.kernel;
		k.bindToInstance(IWeapon, new Nunchaku());

		var w1 = k.get(IWeapon);
		var w2 = k.get(IWeapon);
		Assert.isType(w1, Nunchaku);
		Assert.isType(w2, Nunchaku);
		Assert.areEqual(w1, w2);
	}
}

///// Test classes ////////////////////////////////

class TestModule extends UnjectModule
{
	public override function load()
	{
		bind(IWeapon).to(Sword);

		bind(IMagic).to(Fireball).inSingletonScope();

		bind(Ninja).toSelf();
		bind(Samurai).toSelf();
		bind(Sword).toSelf();

		bind(Katana).toSelf()
			.withParameter("sharpness", 100)
			.withParameter("used", true);
	}
}

class NoInfos { }
class NoConstructor implements Infos { }

class Wakizachi implements Infos
{
	public var sharpness(default, null) : Int;

	public function new(sharpness : Int)
	{
		this.sharpness = sharpness;
	}
}

class Katana implements Infos
{
	public var sharpness : Int;
	public var used : Bool;

	public function new(sharpness : Int, used : Bool)
	{
		this.sharpness = sharpness;
		this.used = used;
	}
}

class Ninja implements Infos
{
	var weapon : IWeapon;
	public var magic : IMagic;

	public function new(weapon : IWeapon, magic : IMagic)
	{
		this.weapon = weapon;
		this.magic = magic;
	}

	public function sneakAttack(target : String)
	{
		return weapon.hit(target) + " (Sneaky)";
	}

	public function doMagic()
	{
		return magic.castSpell();
	}
}

class Samurai implements Infos
{
	var weapon : IWeapon;

	public function new(weapon : IWeapon)
	{
		this.weapon = weapon;
	}

	public function attack(target : String)
	{
		return weapon.hit(target);
	}
}

// Should not be mapped
interface IShogun
{
	public function rule() : Void;
}

class Japan implements Infos
{
	public var shogun(default, null) : IShogun;

	public function new(shogun : IShogun)
	{
		this.shogun = shogun;
	}
}

interface IWeapon
{
	function hit(target : String) : String;
}

interface IMagic implements Infos
{
	function castSpell() : String;
}

class Fireball implements IMagic, implements Infos
{
	public function new() {}

	public function castSpell()
	{
		return "Throws a fireball into the air.";
	}
}

class Sword implements IWeapon, implements Infos
{
	public function new() {}

	public function hit(target : String)
	{
		return "Chopped " + target + " in half.";
	}
}

class MagicSword implements IWeapon
{
	public function new(boundSpell : IMagic) {}

	public function hit(target : String)
	{
		return "Chopped " + target + " in half.";
	}
}

class Nunchaku implements IWeapon
{
	public function new() {}

	public function hit(target : String)
	{
		return "Broken " + target + " in half.";
	}
}
