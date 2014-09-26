angular.module('nxSession',['ng'])
.factory "nxSessionFactory", ['$http','$q',($http,$q) ->
  nxSessionFactory = (options) ->
    options = options || {}

    apiRootPath = options.apiRootPath
    defaultSchemas = options.defaultSchemas
    Session = {}


    class nxChain
      constructor: (@chainName, @doc)->
        @params= {}

      param: (key, value)->
        @params[key] = value
        @

      execute: (resultType)->
        resultType = if resultType? then resultType else "blob"

        $http.post(apiRootPath + @doc.getResourceUrl() + "/@op/" + @chainName, {params: @params}).then (response)->
          #TODO Add deserialization and encapsulation based on expected resultType
          response.data

    class nxAdapter
      constructor: (json)->
        angular.extend this,json

      save: ()->
        doc = new nxDocument(@value.id)
        self = @
        $http.post(apiRootPath + doc.getResourceUrl() + "/@bo/" + @['entity-type'], @).then (response)->
          angular.extend self, response.data
          self

    class nxDocument
      constructor: (pathOrId, jsonDoc) ->
        if jsonDoc? then angular.extend @,jsonDoc
        @pathOrId = pathOrId

      fetch: (schemas)->
        schemas = ( schemas || [])
        self = @
        promise = $http.get(apiRootPath + @getResourceUrl(),
            headers: 
              "X-NXDocumentProperties": schemas.join(",")
        )
        @$resolved = false;

        markResolved = ()-> @$resolved = true
        promise.then(markResolved,markResolved)

        self.$then = promise.then((response)->
          thhen = self.$then
          resolved = self.$resolved

          #angular.extend self, response.data
          angular.copy(response.data, self);
          self.$then = thhen
          self.$resolved = resolved
          delete self.pathOrId
          self
        ).then
        
        self

      _getPathOrId: ()->
        if @uid? then @uid else @pathOrId


      getResourceUrl: ()->
        if @uid? then "/id/" + @uid else if(@_getPathOrId()[0] == "/")
          "/path" + if @pathOrId == "/" then "/" else @pathOrId
        else
          "/id/" + @pathOrId            

      getChildren: (schemas)->
        schemas = ( schemas || [])

        $http.get(apiRootPath + @getResourceUrl() + "/@children"
          headers: 
              "X-NXDocumentProperties": schemas.join(",")
        ).then (response)->
          docs = response.data
          if(angular.isArray(docs.entries))
            docs.entries = docs.entries.map( (jsonDoc)-> new nxDocument(jsonDoc.uid, jsonDoc))
            docs
          else
            $q.reject("Response was not a collection")

      isFolderish: ()->      
        if angular.isDefined(@facets) then @facets.indexOf("Folderish") != -1 else false

      save: (batchId)->

        config = 
            headers:
              "X-Batch-Id":batchId

        $http.put(apiRootPath + "/id/" + @uid , @, config).then (response)->
          new nxDocument(response.data.uid, response.data)

      delete: ()->
        $http.delete(apiRootPath + @getResourceUrl(), @)
          


      setPropertyValue: (property, value)->
        @properties[property] = value

      op: (chainName)->
        new nxChain(chainName, @)


      search: (query)->
        $http.get(apiRootPath + @getResourceUrl() + "/@search?q="+query).then (response)->
          docs = response.data
          if(angular.isArray(docs))
            docs.map( (response)-> new nxDocument(response))
          else
            $q.reject("Response was not a collection")


      getAdapter: (adapterName)->
        $http.get(apiRootPath + @getResourceUrl() + "/@bo/"+adapterName).then (response)->
          new nxAdapter(response.data)

    Session.getDocument = (pathOrId)->
      new nxDocument(pathOrId)

    Session.createDocument = (parentPath,  doc, batchId)->
      doc['entity-type']  = "document"
      config =
          method: "POST"
          url: apiRootPath + "/path" + parentPath 
          data: doc
          headers:
            "X-Batch-Id":batchId

      $http(config).then (response)->
        new nxDocument(response.data.uid, response.data)
  
    Session

]





