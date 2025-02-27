WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS num_actors
    FROM 
        title t
    JOIN 
        aka_title a ON t.id = a.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id
),
top_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        keywords, 
        num_actors,
        RANK() OVER (ORDER BY num_actors DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    tm.title, 
    tm.production_year, 
    tm.num_actors, 
    tm.keywords
FROM 
    top_movies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.num_actors DESC, 
    tm.production_year ASC;
