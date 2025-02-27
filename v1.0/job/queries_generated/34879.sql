WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 1990
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
        JOIN movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
role_distribution AS (
    SELECT 
        ci.role_id,
        rt.role,
        COUNT(DISTINCT ci.person_id) AS total_roles
    FROM 
        cast_info ci
        JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.role_id, rt.role
),
movie_keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    MAX(rd.total_roles) AS max_roles
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keyword_count mkc ON mh.movie_id = mkc.movie_id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    role_distribution rd ON cc.subject_id = rd.role_id
WHERE 
    mh.depth <= 3
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mkc.keyword_count
HAVING 
    MAX(rd.total_roles) IS NULL OR MAX(rd.total_roles) > 5
ORDER BY 
    mh.production_year DESC,
    keyword_count DESC;
