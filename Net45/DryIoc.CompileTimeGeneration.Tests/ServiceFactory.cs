﻿using System;
using System.Collections.Generic;

namespace DryIoc.CompileTimeGeneration.Tests
{
    public partial class ServiceFactory : IResolverWithScopes, IResolverProvider
    {
        public IScope SingletonScope { get; private set; }

        public IScope CurrentScope
        {
            get { throw new NotImplementedException(); }
        }

        public ServiceFactory()
        {
            SingletonScope = new Scope();
        }

        public IResolverWithScopes Resolver
        {
            get { return this; }
        }

        public object ResolveDefault(Type serviceType, IfUnresolved ifUnresolved)
        {
            var factoryDelegate = DefaultResolutions.GetValueOrDefault(serviceType);
            return factoryDelegate == null 
                ? ifUnresolved == IfUnresolved.ReturnDefault ? null
                    : Throw.Instead<object>(Error.UNABLE_TO_RESOLVE_SERVICE, serviceType)
                : factoryDelegate(AppendableArray.Empty, this, null);
        }

        public object ResolveKeyed(Type serviceType, object serviceKey, IfUnresolved ifUnresolved, Type requiredServiceType)
        {
            var factoryDelegate = KeyedResolutions.GetValueOrDefault(new KV<Type, object>(serviceType, serviceKey));
            return factoryDelegate == null
                ? ifUnresolved == IfUnresolved.ReturnDefault ? null
                    : Throw.Instead<object>(Error.UNABLE_TO_RESOLVE_SERVICE, serviceType)
                : factoryDelegate(AppendableArray.Empty, this, null);
        }

        public object ResolvePropertiesAndFields(object instance, PropertiesAndFieldsSelector selectPropertiesAndFields)
        {
            throw new NotImplementedException();
        }

        public IEnumerable<object> ResolveMany(Type serviceType, object serviceKey, Type requiredServiceType, object compositeParentKey)
        {
            throw new NotImplementedException();
        }
    }
}