WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        m.linked_movie_id,
        1 AS level
    FROM 
        title mt
    LEFT JOIN 
        movie_link m ON mt.id = m.movie_id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        m.linked_movie_id,
        mh.level + 1
    FROM 
        title mt
    INNER JOIN 
        movie_link m ON mt.id = m.linked_movie_id
    INNER JOIN 
        movie_hierarchy mh ON m.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    cd.total_cast,
    cd.cast_names,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    mh.level,
    ARRAY_TO_STRING(ARRAY(
        SELECT DISTINCT 
            k.keyword
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        WHERE 
            mk.movie_id = mh.movie_id
    ), ', ') AS movie_keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    keyword_counts kc ON mh.movie_id = kc.movie_id
ORDER BY 
    mh.production_year DESC,
    mh.title;
