WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.person_id
), movie_summary AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        STRING_AGG(DISTINCT an.name, ', ') AS actors,
        COUNT(DISTINCT mk.keyword) AS total_keywords,
        COALESCE(mi.info, 'No info') AS movie_info
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mt.movie_id
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_info mi ON mt.movie_id = mi.movie_id AND mi.info_type_id IN (
            SELECT id FROM info_type WHERE info IN ('Box Office', 'Awards')
        )
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.movie_id, mt.title, mt.production_year, mi.info
), actor_movies AS (
    SELECT 
        ci.person_id,
        SUM(CASE WHEN ci.nr_order <= 5 THEN 1 ELSE 0 END) AS top_role_movies,
        COUNT(DISTINCT ci.movie_id) AS all_movies
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
)
SELECT 
    m.title, 
    m.production_year, 
    m.actors, 
    m.total_keywords, 
    m.movie_info, 
    ah.total_movies AS movies_by_actor,
    am.top_role_movies,
    CASE 
        WHEN am.all_movies > 0 THEN ROUND(CAST(am.top_role_movies AS FLOAT) / am.all_movies * 100, 2) 
        ELSE 0 
    END AS percentage_top_roles
FROM 
    movie_summary m
JOIN 
    actor_hierarchy ah ON m.actors LIKE '%' || ah.person_id || '%'
JOIN 
    actor_movies am ON ah.person_id = am.person_id
WHERE 
    m.total_keywords > 0
ORDER BY 
    m.production_year DESC, 
    percentage_top_roles DESC
LIMIT 50;
