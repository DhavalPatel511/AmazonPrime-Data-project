import pandas as pd
import sqlalchemy as sql

df = pd.read_csv('amazon_prime_titles.csv')
import sqlalchemy as sal
engine = sql.create_engine('mssql://Dhaval\\SQLEXPRESS/master?driver=ODBC+Driver+17+for+SQL+Server')
conn=engine.connect()

df.to_sql('amazonprime_raw', con=conn , index=False, if_exists = 'append')
conn.close()

df.head()
df.isna().sum()