WITH RECURSIVE TitleHierarchy AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        t.episode_of_id,
        1 AS hierarchy_level
    FROM 
        title t
    WHERE 
        t.episode_of_id IS NULL  -- Root titles without episodes
    
    UNION ALL
    
    SELECT 
        e.id,
        e.title,
        e.production_year,
        e.season_nr,
        e.episode_nr,
        e.episode_of_id,
        th.hierarchy_level + 1
    FROM 
        title e
    INNER JOIN 
        TitleHierarchy th ON e.episode_of_id = th.id
)

SELECT 
    tn.name,
    tt.title,
    COALESCE(c.role_id, -1) AS role_id,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    AVG(CASE WHEN mi.info_type_id = 1 THEN LENGTH(mi.info) ELSE NULL END) AS avg_info_length,
    COUNT(DISTINCT cm.kind) FILTER (WHERE cm.kind IS NOT NULL) AS unique_company_count
FROM 
    aka_name tn
LEFT JOIN 
    cast_info c ON tn.person_id = c.person_id
INNER JOIN 
    complete_cast cc ON c.movie_id = cc.movie_id
INNER JOIN 
    TitleHierarchy tt ON cc.movie_id = tt.id
LEFT JOIN 
    movie_keyword mk ON tt.id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON tt.id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    comp_cast_type cm ON c.person_role_id = cm.id
LEFT JOIN 
    movie_info mi ON tt.id = mi.movie_id
WHERE 
    tt.production_year >= 2000
    AND tn.id IS NOT NULL
GROUP BY 
    tn.name, tt.title, c.role_id
ORDER BY 
    keyword_count DESC, avg_info_length DESC;
