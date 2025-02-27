WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || m.title AS VARCHAR(255)) AS path
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.path,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    COUNT(DISTINCT mk.keyword) AS total_keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id AND ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, mh.path
HAVING 
    total_keywords > 5 OR COUNT(DISTINCT ci.person_id) > 3
ORDER BY 
    mh.production_year DESC, total_cast DESC;

WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS ranking
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.ranking,
    COALESCE(kw.total_keywords, 0) AS total_keywords
FROM 
    ranked_movies rm
LEFT JOIN (
    SELECT 
        movie_id,
        COUNT(DISTINCT keyword) AS total_keywords
    FROM 
        movie_keyword
    GROUP BY 
        movie_id
) kw ON rm.movie_id = kw.movie_id
WHERE 
    rm.ranking <= 5
ORDER BY 
    rm.production_year, rm.ranking;
