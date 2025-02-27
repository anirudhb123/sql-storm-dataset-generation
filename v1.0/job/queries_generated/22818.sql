WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(m.note, 'No Note') AS note,
        COALESCE(c.id, -1) AS company_id,
        COALESCE(c.name, 'Unknown Company') AS company_name,
        c.country_code,
        0 AS depth
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.note,
        COALESCE(c2.id, -1),
        COALESCE(c2.name, 'Unknown Company'),
        c2.country_code,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_companies mc2 ON mh.movie_id = mc2.movie_id
    LEFT JOIN 
        company_name c2 ON mc2.company_id = c2.id
    WHERE 
        mh.depth < 5
    AND 
        c2.id IS NOT NULL
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.note,
    mh.company_id,
    mh.company_name,
    mh.country_code,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.depth DESC) AS company_hierarchy_level,
    (SELECT COUNT(*) FROM company_name c3 WHERE c3.country_code = mh.country_code) AS country_company_count,
    CASE 
        WHEN mh.depth = 0 THEN 'Original Movie' 
        ELSE 'Collaborative Production' 
    END AS production_type,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    (mh.country_code IS NOT NULL AND 
     mh.production_year > 2000 OR mh.note LIKE '%blockbuster%')
AND 
    (mh.company_id IS NULL OR mh.company_id != -1)
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.note, mh.company_id, mh.company_name, mh.country_code
HAVING 
    COUNT(k.id) >= 3
ORDER BY 
    mh.production_year DESC, company_hierarchy_level ASC;
