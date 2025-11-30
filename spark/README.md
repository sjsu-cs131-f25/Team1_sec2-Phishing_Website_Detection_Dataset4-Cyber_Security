How to run the job: 
    Upload the script onto the bucket and then run it to see the jobs in dataproc. 
    Attach to the VM after defining the project name and region.

Location of data: 
    Data location is in the bucket 

About the data and google cloud: 
Our pipeline runs on Google Cloud Dataproc Serverless, where our dataset and PySpark script are stored in a shared GCS bucket. When the job is submitted, Dataproc automatically provides executors, reads the data from GCS, performs all transformations (cleaning, aggregations, correlations, ML training), and then writes the final parquet outputs back to GCS. Data never lives on a single machine, every stage runs across multiple distributed workers, and results are written directly back to cloud storage.


