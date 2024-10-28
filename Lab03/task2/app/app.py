import psycopg2

from flask import Flask, abort, redirect, render_template, request, url_for

app = Flask(__name__)

def get_db_connection():
    conn = psycopg2.connect(
        host='db',
        database='main_db',
        user='postgres',
        password='postgres'
    )
    return conn

def create_table():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('''
        CREATE TABLE IF NOT EXISTS t1 (
            id integer PRIMARY KEY,
            a INTEGER,
            b INTEGER
        );
    ''')
    conn.commit()
    cur.close()
    conn.close()

@app.route('/add_item', methods=['POST'])
def add_item():
    # validate input data
    a = request.form.get('a')
    b = request.form.get('b')
    if a is None or b is None:
        abort(400)
    try:
        a = int(a)
    except ValueError:
        abort(400)
    # Insert new record into our database:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('INSERT INTP t(a, b) VALUES (?, ?)', (a, b))
        conn.commit()
        cur.close()
        conn.close()
        # Redirect to the main page:
        return redirect(url_for('main_page'))

@app.route('/')
def main_page(): 
    create_table()
    return "<h1> Main page. Welcome to PostgreSQL! </h1>"

@app.route('/table') # callback for request routes
def view_table():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute('SELECT * FROM t1')

    ret =  render_template(
        'main_page.html', 
        columns=[x[0] for x in cur.description],
        data=cur.fetchall()
    )
    cur.close()
    conn.close()
    return ret

if __name__ == '__main__':
    app.run('0.0.0.0', port=8080, debug=True)