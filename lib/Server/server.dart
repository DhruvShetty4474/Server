import 'package:mongo_dart/mongo_dart.dart';

import 'constant.dart'; // Ensure this import is included


// Connect to MongoDB Server
class MongoDB_Server {
  static late Db db;
  static late DbCollection collection;

//Creates an instance of DataBase connection and DbCollection.
  static Future<void> connect() async {
     try {
       db = await Db.create(MONGO_URL);
       await db.open();
       collection = db.collection(COLLECTION_NAME);
       print("Connected to MongoDB!");
       // print(await collection.find().toList());
     } catch (e) {
       print('MongoDB connection failed, retrying in 5 seconds...');
       await Future.delayed(Duration(seconds: 5));
       await connect(); // Retry
     }
  }
  // Watches for changes in the collection
  static Stream<Map<String, dynamic>> watchChanges() async* {

    //Check if collection is empty.
    if (collection == null) {
      throw Exception("Database connection is not established. Call connect() first.");
    }
    // Define the pipeline to filter for insert, update, and delete operations
    var pipeline = [
      {
        '\$match': {
          'operationType': {'\$in': ['insert', 'update', 'delete']},
        }
      }
    ];

    // Pass the pipeline to the watch() method
    await for (var change in collection.watch(pipeline)){
      // Logic for getting response from insert, update, and delete operations in database
      if (change.operationType == 'insert') {
        print("Data Inserted");
        // return change.fullDocument ?? {};
        yield  {'operation': 'insert', "data": change.fullDocument as Map<String, dynamic>};

      }
      // When Data is been updated
      else if(change.operationType == 'update'){
        print("Data Updated");
        //check if full document is available
        if (change.fullDocument != null) {
          // print('Full document after update: ${change.fullDocument as Map<String, dynamic>}');
          yield {'operation': 'update', 'data': change.fullDocument as Map<String, dynamic>};
        }
        else {
          // Fetch the full document manually if not available
          var updatedDocument =  await collection.findOne({'_id': change.documentKey?['_id']});
          if (updatedDocument != null) {
            yield {'operation': 'update', 'data': updatedDocument};
          } else {
            print("Could not fetch updated document");
            yield {'operation': 'update', '_id': change.documentKey?['_id']}; // At least return _id
          }
        }
      }
      // When Data is been deleted returns the id
      else if (change.operationType == 'delete') {
        print('Document deleted:');
        // print('Document ID: ${change.documentKey?['_id']}');
        // print('Deleted user: ${change.fullDocument?['name']}');
        yield {'operation': 'delete', 'document_id': change.documentKey?['_id']};
      }
    }
  }
}
