WITH RECURSIVE RecursiveCTE AS (
    SELECT 
        mc.movie_id, 
        m.title, 
        1 AS depth 
    FROM 
        movie_companies mc 
    JOIN 
        aka_title m ON mc.movie_id = m.movie_id 
    WHERE 
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Production')
    
    UNION ALL
    
    SELECT 
        mc.movie_id, 
        CONCAT(rc.title, ' > ', m.title) AS title, 
        rc.depth + 1 
    FROM 
        movie_companies mc 
    JOIN 
        aka_title m ON mc.movie_id = m.movie_id 
    JOIN 
        RecursiveCTE rc ON mc.movie_id = rc.movie_id 
    WHERE 
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Distributor')
)
SELECT 
    r.movie_id,
    r.title,
    k.keyword,
    COUNT(*) OVER(PARTITION BY r.movie_id) AS total_movies,
    COUNT(DISTINCT ci.person_id) AS total_casts,
    MAX(CASE WHEN k.keyword LIKE '%action%' THEN 'Action Genre' ELSE NULL END) AS genre_label
FROM 
    RecursiveCTE r
LEFT JOIN 
    movie_keyword mk ON r.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON r.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON r.movie_id = ci.movie_id
WHERE 
    ci.role_id IN (SELECT id FROM role_type WHERE role LIKE '%lead%')
    AND r.depth < 4 -- Limiting the depth to prevent excessive recursion
GROUP BY 
    r.movie_id, r.title, k.keyword
ORDER BY 
    total_casts DESC, r.title;
