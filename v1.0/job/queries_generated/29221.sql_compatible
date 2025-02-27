
WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id, 
        title.title AS movie_title, 
        aka_name.name AS actor_name, 
        title.production_year, 
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id) AS rank
    FROM 
        title
    JOIN 
        movie_info ON title.id = movie_info.movie_id
    JOIN 
        aka_title ON title.id = aka_title.movie_id 
    JOIN 
        cast_info ON aka_title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        movie_info.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
        AND aka_name.name IS NOT NULL
        AND title.production_year BETWEEN 2000 AND 2020
),
keyworded_movies AS (
    SELECT 
        rm.movie_id, 
        rm.movie_title, 
        rm.production_year, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year
)
SELECT 
    km.movie_title, 
    km.production_year, 
    km.keywords, 
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = km.movie_id) AS actor_count
FROM 
    keyworded_movies km
WHERE 
    km.keywords ILIKE '%action%' OR km.keywords ILIKE '%drama%'
ORDER BY 
    km.production_year DESC, actor_count DESC
LIMIT 10;
