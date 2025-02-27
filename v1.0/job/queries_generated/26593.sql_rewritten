WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        string_agg(DISTINCT ak.name, ', ') AS actor_names,
        string_agg(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        cast_info c ON c.movie_id = t.id
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword kw ON kw.id = mk.keyword_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        actor_names, 
        keywords
    FROM 
        movie_data
    ORDER BY 
        cast_count DESC
    LIMIT 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actor_names,
    tm.keywords,
    ct.kind AS company_type
FROM 
    top_movies tm
JOIN 
    movie_companies mc ON mc.movie_id = tm.movie_id
JOIN 
    company_type ct ON ct.id = mc.company_type_id
ORDER BY 
    tm.cast_count DESC, 
    tm.production_year DESC;