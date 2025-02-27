WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopRankedTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.rn <= 5
),
CastWithRoles AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
MoviesWithMissingInfo AS (
    SELECT 
        mt.movie_id
    FROM 
        movie_info mt
    LEFT JOIN 
        movie_info_idx mi ON mt.movie_id = mi.movie_id
    WHERE 
        mi.id IS NULL
    GROUP BY 
        mt.movie_id
)
SELECT 
    t.title,
    t.production_year,
    c.roles,
    CASE 
        WHEN mi.info IS NULL THEN 'NO INFO'
        ELSE mi.info
    END AS info,
    CASE 
        WHEN mc.company_id IS NOT NULL THEN 'Company info available'
        ELSE 'Company info missing'
    END AS company_status,
    COALESCE(
        LENGTH(t.title) - LENGTH(REPLACE(t.title, ' ', '')), 0
    ) AS space_count,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    TopRankedTitles t
LEFT JOIN 
    CastWithRoles c ON c.movie_id = t.title_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.title_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    MoviesWithMissingInfo mi ON mi.movie_id = t.title_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.title_id
WHERE 
    t.production_year >= 2000
    AND (t.title LIKE '%Adventure%' OR t.title LIKE '%Drama%')
GROUP BY 
    t.title, t.production_year, c.roles, mi.info, mc.company_id
ORDER BY 
    t.production_year DESC, space_count DESC;
