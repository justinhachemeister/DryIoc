﻿using NUnit.Framework;

namespace DryIoc.IssuesTests
{
    [TestFixture]
    public class Issue181_RegisterInstanceUnregister
    {
        [Test]
        public void Test_without_Unregister()
        {
            var container = new Container();

            container.Register(typeof(Printer));

            var test = new Test { N = 1 };
            container.UseInstance<ITest>(test);
            var printer = container.Resolve<IPrinter, Printer>();
            Assert.AreEqual("1", printer.Print()); // prints '1' as expected

            test = new Test { N = 2 };
            container.UseInstance<ITest>(test);

            Assert.AreEqual(2, container.Resolve<ITest>().N); // does not throws, replaced dependency

            printer = container.Resolve<IPrinter, Printer>();
            Assert.AreEqual("2", printer.Print()); // prints '1', I would expect this to print '2'
        }
        private class Printer : IPrinter
        {
            private readonly ITest _test;

            public Printer(ITest test)
            {
                _test = test;
            }

            public string Print()
            {
                return _test.N.ToString();
            }
        }

        private interface IPrinter
        {
            string Print();
        }

        private interface ITest
        {
            int N { get; }
        }

        private class Test : ITest
        {
            public int N { get; set; }
        }
    }
}
