
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(ct.kind, 'Unknown') AS company_type,
        COALESCE(a.name, 'Unknown') AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY COALESCE(a.name, 'Unknown')) AS rn
    FROM 
        aka_title m
    LEFT JOIN
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    LEFT JOIN 
        aka_name a ON a.person_id = ci.person_id 
    WHERE 
        m.production_year IS NOT NULL AND m.production_year > 2000
),
keyword_summary AS (
    SELECT 
        mk.movie_id, 
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
actor_count AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT actor_name) AS actor_count
    FROM 
        movie_hierarchy
    GROUP BY 
        movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    k.keywords_list,
    ac.actor_count,
    CASE 
        WHEN ac.actor_count IS NULL THEN 'No Actors'
        WHEN ac.actor_count > 5 THEN 'Large Cast'
        WHEN ac.actor_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    CASE 
        WHEN mh.company_type ILIKE '%Dream%' THEN 'Dreamworks Related'
        ELSE 'Other'
    END AS company_type_analysis
FROM 
    movie_hierarchy mh
LEFT JOIN 
    keyword_summary k ON mh.movie_id = k.movie_id
LEFT JOIN 
    actor_count ac ON mh.movie_id = ac.movie_id
WHERE 
    mh.rn = 1 
ORDER BY 
    mh.production_year DESC NULLS LAST, 
    mh.title ASC NULLS FIRST;
