WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        COUNT(ci.person_id) AS cast_count
    FROM 
        title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = m.id
    GROUP BY 
        m.id, m.title, m.production_year, m.kind_id
),
top_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        kind_id,
        cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        ranked_movies
    WHERE 
        production_year >= 2000
),
actor_names AS (
    SELECT 
        ak.name AS actor_name,
        cc.movie_id,
        ROW_NUMBER() OVER (PARTITION BY cc.movie_id ORDER BY ak.name) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
),
movie_details AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        ak.actor_name,
        ak.actor_order
    FROM 
        top_movies tm
    LEFT JOIN 
        actor_names ak ON tm.movie_id = ak.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    STRING_AGG(md.actor_name, ', ' ORDER BY md.actor_order) AS actors
FROM 
    movie_details md
GROUP BY 
    md.movie_id, md.title, md.production_year
ORDER BY 
    md.production_year DESC,
    md.movie_id;
