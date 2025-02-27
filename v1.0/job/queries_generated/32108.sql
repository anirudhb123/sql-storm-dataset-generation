WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        aka_title m
    JOIN
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.level
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
)
SELECT 
    t.title,
    t.production_year,
    t.cast_count,
    COALESCE(kw.keyword, 'No Keywords') AS keyword,
    ci.role_id,
    c.name AS company_name,
    CASE 
        WHEN k.id IS NULL THEN 'No association'
        ELSE 'Linked movie exists'
    END AS linkage_status
FROM 
    TopMovies t
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    complete_cast cc ON t.movie_id = cc.movie_id
LEFT JOIN 
    role_type rt ON cc.status_id = rt.id
LEFT JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_info mi ON t.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
WHERE 
    t.rank <= 10
ORDER BY 
    t.production_year DESC, 
    t.cast_count DESC;

This SQL query performs a multi-level recursive Common Table Expression (CTE) to extract movies produced after 2000 and their associated cast members, while including hierarchical relationships for episodic content. It aggregates cast counts and ranks them by year within levels, filtering to include only significant cast contributions. It also retrieves relevant keywords, associated companies, and budget information while allowing for null checks and conditional logic on links between movies and keywords.
