WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
), aggregated_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_cast,
        MIN(mk.keyword) AS first_keyword,
        MAX(mk.keyword) AS last_keyword,
        ROW_NUMBER() OVER (PARTITION BY mh.kind_id ORDER BY mh.production_year DESC) AS movie_rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.kind_id
)
SELECT 
    am.title,
    am.production_year,
    am.total_cast,
    am.noted_cast,
    am.first_keyword,
    am.last_keyword
FROM 
    aggregated_movies am
WHERE 
    am.production_year >= 2000
    AND am.movie_rank <= 10
    AND (am.total_cast IS NOT NULL OR am.first_keyword IS NULL)
ORDER BY 
    am.production_year DESC, am.title;
