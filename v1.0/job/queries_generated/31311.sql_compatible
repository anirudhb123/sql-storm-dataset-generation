
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth,
        mt.episode_of_id,
        ARRAY[mt.id] AS path
    FROM 
        aka_title AS mt
    WHERE 
        mt.episode_of_id IS NULL 
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1,
        m.episode_of_id,
        mh.path || m.id
    FROM 
        aka_title AS m
    JOIN 
        movie_hierarchy AS mh ON mh.movie_id = m.episode_of_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT ak.name) AS cast_names
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS total_keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cs.total_cast,
        ks.total_keywords,
        mh.depth,
        mh.path
    FROM 
        movie_hierarchy AS mh
    LEFT JOIN 
        cast_summary AS cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        keyword_summary AS ks ON mh.movie_id = ks.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.total_cast, 0) AS total_cast,
    COALESCE(md.total_keywords, 0) AS total_keywords,
    md.depth,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
FROM 
    movie_details AS md
LEFT JOIN 
    cast_info AS ci ON md.movie_id = ci.movie_id
LEFT JOIN 
    aka_name AS ak ON ak.person_id = ci.person_id
WHERE 
    md.production_year BETWEEN 2000 AND 2023 
GROUP BY 
    md.movie_id, md.title, md.production_year, md.total_cast, md.total_keywords, md.depth
ORDER BY 
    md.production_year DESC, total_cast DESC;
