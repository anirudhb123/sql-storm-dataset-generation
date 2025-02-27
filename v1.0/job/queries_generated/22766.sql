WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year > 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        a.title AS movie_title,
        a.production_year,
        mh.level + 1
    FROM
        movie_link ml
        JOIN aka_title a ON ml.linked_movie_id = a.id
        JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        a.production_year IS NOT NULL
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') FILTER (WHERE ak.name IS NOT NULL) AS actors,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords,
    COALESCE(CASE 
        WHEN mh.level > 1 THEN 
            CONCAT('Sequel Level ', mh.level)
        ELSE 
            'Original'
    END, 'Unknown') AS sequel_status
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    mh.production_year BETWEEN 2005 AND 2023
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, mh.level
ORDER BY 
    mh.production_year DESC, actor_count DESC
HAVING 
    COUNT(DISTINCT k.keyword) > 3 OR COUNT(DISTINCT ak.name) > 5
LIMIT 100;
