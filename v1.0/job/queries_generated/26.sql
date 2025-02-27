WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title AS t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        AND t.production_year IS NOT NULL
),
CastCount AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast
    FROM 
        cast_info AS c
    GROUP BY 
        c.movie_id
)
SELECT 
    a.name AS actor_name,
    rt.title AS movie_title,
    rt.production_year,
    CASE 
        WHEN cc.total_cast IS NULL THEN 0
        ELSE cc.total_cast
    END AS cast_count,
    COALESCE(NULLIF(cc.total_cast, 0), 1) AS adjusted_cast_count,
    CONCAT(a.name, ' starred in ', rt.title) AS description
FROM 
    aka_name AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    RankedTitles AS rt ON c.movie_id = rt.id
LEFT JOIN 
    CastCount AS cc ON rt.id = cc.movie_id
WHERE 
    rt.rn <= 10
    AND a.id IS NOT NULL
ORDER BY 
    rt.production_year DESC, cast_count DESC;
