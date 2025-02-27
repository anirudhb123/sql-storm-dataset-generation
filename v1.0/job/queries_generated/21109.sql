WITH ranked_movies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
        AND at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
actor_information AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(ci.id) AS movie_count,
        STRING_AGG(DISTINCT tt.title, ', ') AS titles,
        SUM(CASE WHEN mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'short')) THEN 1 ELSE 0 END) AS movie_roles
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title tt ON ci.movie_id = tt.id
    LEFT JOIN 
        movie_companies mc ON tt.id = mc.movie_id
    LEFT JOIN 
        kind_type kt ON kt.id = tt.kind_id
    LEFT JOIN 
        movie_info mi ON tt.id = mi.movie_id
    WHERE 
        ak.name IS NOT NULL
        AND ak.name NOT LIKE '%[0-9]%'
        AND ak.name NOT IN (SELECT name FROM char_name WHERE name IS NOT NULL)
    GROUP BY 
        ak.name
),
notable_actors AS (
    SELECT 
        actor_name,
        movie_count,
        titles,
        movie_roles,
        CASE 
            WHEN movie_count > 5 THEN 'Prolific Actor'
            WHEN movie_roles > 5 THEN 'Specialized Actor'
            ELSE 'Newcomer'
        END AS actor_category
    FROM 
        actor_information
    WHERE 
        movie_count > 0
)
SELECT 
    ra.title AS movie_title,
    ra.production_year,
    na.actor_name,
    na.actor_category,
    na.titles,
    ra.year_rank
FROM 
    ranked_movies ra
LEFT JOIN 
    notable_actors na ON na.titles LIKE '%' || ra.title || '%'
WHERE 
    ra.year_rank <= 10
ORDER BY 
    ra.production_year DESC,
    na.actor_category,
    ra.title;

