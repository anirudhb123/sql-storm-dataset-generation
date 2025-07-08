
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(mt.season_nr, 0) AS season_nr,
        COALESCE(mt.episode_nr, 0) AS episode_nr,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(mt.season_nr, 0),
        COALESCE(mt.episode_nr, 0),
        mh.level + 1
    FROM 
        aka_title mt
    INNER JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS has_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    m.id AS movie_id,
    m.title,
    m.production_year,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.has_roles, 0) AS has_roles,
    COALESCE(ks.keywords, 'No keywords') AS keywords,
    mh.level
FROM 
    aka_title m
LEFT JOIN 
    cast_summary cs ON m.id = cs.movie_id
LEFT JOIN 
    keyword_summary ks ON m.id = ks.movie_id
LEFT JOIN 
    movie_hierarchy mh ON m.id = mh.movie_id
WHERE 
    m.production_year >= 2000
    AND (m.title ILIKE '%action%' OR m.title ILIKE '%drama%')
GROUP BY 
    m.id, m.title, m.production_year, cs.total_cast, cs.has_roles, ks.keywords, mh.level
ORDER BY 
    mh.level ASC,
    m.production_year DESC,
    m.title ASC;
