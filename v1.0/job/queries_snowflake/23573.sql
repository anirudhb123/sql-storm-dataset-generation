
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mt.episode_of_id
    FROM 
        aka_title mt
    JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(*) OVER (PARTITION BY mh.production_year) AS movies_per_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rank_per_year
    FROM 
        movie_hierarchy mh
),
cast_info_enriched AS (
    SELECT 
        ci.movie_id,
        COUNT(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 END) AS roles_count,
        LISTAGG(DISTINCT na.name, ', ') WITHIN GROUP (ORDER BY na.name) AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name na ON ci.person_id = na.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    rm.movies_per_year,
    rm.rank_per_year,
    ci.roles_count,
    ci.actor_names,
    CASE 
        WHEN rm.production_year < 1990 THEN 'Classic Movie'
        WHEN rm.production_year BETWEEN 1990 AND 2010 THEN 'Modern Movie'
        ELSE 'Recent Movie'
    END AS movie_category,
    COALESCE(ci.roles_count, 0) AS safe_roles_count,
    COALESCE(NULLIF(ci.actor_names, ''), 'Unknown Cast') AS displayed_names
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_info_enriched ci ON rm.movie_id = ci.movie_id
WHERE 
    rm.movies_per_year > 1 
    OR rm.production_year = (SELECT MAX(production_year) FROM aka_title)
ORDER BY 
    rm.production_year DESC, 
    rm.rank_per_year;
