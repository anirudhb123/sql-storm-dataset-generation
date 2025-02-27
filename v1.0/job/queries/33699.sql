
WITH RECURSIVE popular_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON ci.movie_id = t.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(ci.person_id) > 5
),
recent_movies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        popular_movies 
    WHERE 
        production_year >= EXTRACT(YEAR FROM DATE '2024-10-01') - 5
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(p.name, 'Unknown') AS primary_actor
FROM 
    recent_movies r
LEFT JOIN 
    movie_keywords mk ON mk.movie_id = r.movie_id
LEFT JOIN 
    (SELECT 
         ci.movie_id,
         a.name
     FROM 
         cast_info ci
     JOIN 
         aka_name a ON a.person_id = ci.person_id
     WHERE 
         ci.nr_order = 1) p ON p.movie_id = r.movie_id
ORDER BY 
    r.production_year DESC, 
    r.title ASC;
