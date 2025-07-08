WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 
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
    WHERE 
        mh.level < 3
),
avg_cast_info AS (
    SELECT 
        ci.movie_id,
        AVG(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS avg_null_notes,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id, 
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword ILIKE '%action%'
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(aki.name, 'Unknown') AS lead_actor,
    COALESCE(aki.name, 'Unknown') AS lead_actor,
    a.avg_null_notes,
    a.total_cast,
    mk.keyword AS movie_genre
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name aki ON ci.person_id = aki.person_id AND aki.md5sum IS NOT NULL
LEFT JOIN 
    avg_cast_info a ON mh.movie_id = a.movie_id
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2000
    AND a.avg_null_notes < 0.5
ORDER BY 
    mh.production_year DESC,
    mh.title ASC;