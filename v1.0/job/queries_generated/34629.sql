WITH RECURSIVE movie_actors AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
), 
movies_with_keyword AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
), 
movie_details AS (
    SELECT 
        m.title,
        COALESCE(GROUP_CONCAT(DISTINCT ma.actor_name ORDER BY ma.actor_order), 'No Cast') AS actors,
        COALESCE(GROUP_CONCAT(DISTINCT mwk.keyword ORDER BY mwk.keyword_rank), 'No Keywords') AS keywords,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movies_with_keyword mwk
    JOIN 
        aka_title m ON mwk.movie_id = m.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_actors ma ON m.id = ma.movie_id
    GROUP BY 
        m.id
), 
filtered_movies AS (
    SELECT 
        md.title,
        md.actors,
        md.keywords,
        md.production_year,
        md.company_count
    FROM 
        movie_details md
    WHERE 
        md.production_year IS NOT NULL
        AND md.production_year BETWEEN 2000 AND 2023
        AND md.company_count > 1
)
SELECT 
    title,
    actors,
    keywords,
    production_year,
    company_count
FROM 
    filtered_movies
ORDER BY 
    production_year DESC, 
    title;
