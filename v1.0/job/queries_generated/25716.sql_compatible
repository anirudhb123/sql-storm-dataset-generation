
WITH movie_actors AS (
    SELECT 
        ka.name AS actor_name,
        ak.title AS movie_title,
        ak.production_year,
        c.nr_order AS role_order
    FROM 
        aka_name ka
    JOIN 
        cast_info c ON ka.person_id = c.person_id
    JOIN 
        aka_title ak ON c.movie_id = ak.movie_id
    WHERE 
        ak.production_year BETWEEN 1990 AND 2000
),
keyworded_movies AS (
    SELECT 
        ak.title AS movie_title,
        ak.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title ak
    JOIN 
        movie_keyword mk ON ak.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        ak.production_year BETWEEN 1995 AND 2000
    GROUP BY 
        ak.title, ak.production_year
),
actor_movie_info AS (
    SELECT 
        ma.actor_name,
        ma.movie_title,
        ma.production_year,
        ma.role_order,
        km.keywords
    FROM 
        movie_actors ma
    LEFT JOIN 
        keyworded_movies km ON ma.movie_title = km.movie_title AND ma.production_year = km.production_year
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    keywords,
    CASE 
        WHEN role_order IS NULL THEN 'No role specified'
        ELSE CONCAT('Role order: ', role_order)
    END AS role_description
FROM 
    actor_movie_info
ORDER BY 
    production_year DESC, actor_name, movie_title;
