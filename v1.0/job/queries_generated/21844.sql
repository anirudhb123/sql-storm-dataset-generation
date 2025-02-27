WITH RecursiveCompanyHierarchy AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        1 AS hierarchy_level
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mc.movie_id,
        CONCAT(cn.name, ' (Sub)') AS company_name,
        ct.kind AS company_type,
        rch.hierarchy_level + 1
    FROM 
        RecursiveCompanyHierarchy rch
    JOIN 
        movie_companies mc ON rch.movie_id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL
        AND rch.hierarchy_level < 5
),
MovieWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    rch.company_name,
    rch.company_type,
    COALESCE(mw.keywords[1], 'No keywords') AS first_keyword,
    CASE 
        WHEN rch.hierarchy_level = 1 THEN 'Direct Company'
        WHEN rch.hierarchy_level > 1 AND rch.hierarchy_level < 5 THEN 'Sub Company Level'
        ELSE 'Outsider'
    END AS company_relationship,
    COUNT(DISTINCT ci.movie_id) AS total_movies
FROM 
    cast_info ci 
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    RecursiveCompanyHierarchy rch ON ci.movie_id = rch.movie_id
JOIN 
    MovieWithKeywords mw ON rch.movie_id = mw.movie_id 
LEFT JOIN 
    aka_title m ON ci.movie_id = m.id
WHERE 
    (a.name IS NOT NULL OR a.md5sum IS NULL)
    AND (rch.company_type IS NOT NULL OR rch.company_type = 'Independent')
GROUP BY 
    a.name, m.title, rch.company_name, rch.company_type, mw.keywords
HAVING 
    COUNT(DISTINCT ci.movie_id) > 3
ORDER BY 
    total_movies DESC;
