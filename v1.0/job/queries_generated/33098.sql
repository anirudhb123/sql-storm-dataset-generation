WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        h.level + 1
    FROM 
        aka_title AS e
    INNER JOIN 
        movie_hierarchy AS h ON e.episode_of_id = h.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_names
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
movie_details AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(cs.total_cast, 0) AS total_cast,
        cs.cast_names,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS production_rank
    FROM 
        aka_title AS m
    LEFT JOIN 
        cast_summary AS cs ON m.id = cs.movie_id
    WHERE 
        m.production_year >= 2000
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.cast_names,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    mh.level AS movie_level
FROM 
    movie_details AS md
LEFT JOIN 
    keyword_summary AS ks ON md.movie_id = ks.movie_id
LEFT JOIN 
    movie_hierarchy AS mh ON md.movie_id = mh.movie_id
WHERE 
    md.production_rank <= 5
ORDER BY 
    md.production_year DESC, md.title;
