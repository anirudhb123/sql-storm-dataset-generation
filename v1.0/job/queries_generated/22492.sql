WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title AS m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link AS ml
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
)
, cast_details AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order NULLS LAST) AS actor_rank
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
)
SELECT 
    mh.title,
    mh.production_year,
    md.actor_name AS leading_actor,
    md.actor_count,
    CASE 
        WHEN mh.depth = 1 THEN 'Self-Contained'
        WHEN mh.depth > 1 THEN 'Part of a Series'
        ELSE 'Unclassified'
    END AS movie_classification,
    COALESCE(ki.keyword, 'No Keywords') AS movie_keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    cast_details AS md ON mh.movie_id = md.movie_id AND md.actor_rank = 1
LEFT JOIN 
    movie_keyword AS mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_companies AS mc ON mh.movie_id = mc.movie_id
GROUP BY 
    mh.title, mh.production_year, md.actor_name, mh.depth, ki.keyword
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    mh.production_year DESC,
    actor_count DESC NULLS LAST;
