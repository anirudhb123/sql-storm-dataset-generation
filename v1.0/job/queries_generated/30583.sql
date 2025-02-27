WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000 
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_table AS (
    SELECT 
        ci.movie_id,
        ARRAY_AGG(DISTINCT an.name) AS actor_names,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        ci.role_id IS NOT NULL
    GROUP BY 
        ci.movie_id
),
company_stats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
combined_results AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ct.actor_count,
        cs.company_count,
        ARRAY_TO_STRING(ct.actor_names, ', ') AS actors,
        ARRAY_TO_STRING(cs.company_names, ', ') AS production_companies,
        mh.depth
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_table ct ON mh.movie_id = ct.movie_id
    LEFT JOIN 
        company_stats cs ON mh.movie_id = cs.movie_id
)
SELECT 
    title,
    production_year,
    depth,
    COALESCE(actor_count, 0) AS total_actors,
    COALESCE(company_count, 0) AS total_companies,
    CASE 
        WHEN total_actors > 10 THEN 'Large Cast'
        WHEN total_actors > 0 THEN 'Small Cast'
        ELSE 'No Cast'
    END AS cast_size_category,
    COALESCE(actors, 'No Actors') AS actors_list,
    COALESCE(production_companies, 'No Companies') AS companies_list
FROM 
    combined_results
WHERE 
    (depth = 1 AND production_year >= 2010) OR 
    (depth > 1 AND production_year < 2010)
ORDER BY 
    production_year DESC, depth; 

