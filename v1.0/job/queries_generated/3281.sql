WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
),
actor_movie_counts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
popular_actors AS (
    SELECT 
        a.id AS actor_id,
        na.name AS actor_name,
        ac.movie_count
    FROM 
        aka_name na
    JOIN 
        actor_movie_counts ac ON na.person_id = ac.person_id
    WHERE 
        ac.movie_count >= 5
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END), 'No info') AS runtime_info,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
)
SELECT 
    ma.actor_name,
    md.title,
    md.production_year,
    md.runtime_info,
    md.company_count
FROM 
    popular_actors ma
JOIN 
    cast_info ci ON ma.actor_id = ci.person_id
JOIN 
    movie_details md ON ci.movie_id = md.movie_id
WHERE 
    md.company_count > 0
ORDER BY 
    md.production_year DESC, ma.actor_name;
