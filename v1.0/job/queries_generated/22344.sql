WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
), 

movie_cast AS (
    SELECT 
        c.movie_id,
        c.person_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
)

SELECT 
    mh.level,
    mh.title,
    mh.production_year,
    COALESCE(mca.actor_name, 'Unknown Actor') AS main_actor,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT ci.note, ', ') AS role_notes,
    AVG(i.info::FLOAT) AS average_info_per_movie
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_cast mca ON mh.movie_id = mca.movie_id AND mca.actor_rank = 1
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_info i ON mh.movie_id = i.movie_id AND i.info_type_id IN (
        SELECT id FROM info_type WHERE info LIKE '%Award%'
    )
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
GROUP BY 
    mh.level, mh.title, mh.production_year, main_actor
HAVING 
    COUNT(DISTINCT mk.keyword) >= 3 AND 
    AVG(i.info::FLOAT) IS NOT NULL
ORDER BY 
    mh.production_year DESC, mh.title
LIMIT 100;

-- This query uses CTEs for hierarchical movie relationships and movie casting.
-- It incorporates outer joins to relate movies with their casts and keywords.
-- Additionally, it limits results based on counts of keywords and average information, showcasing the complexity of semantic filtering.
