WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
PersonRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        rt.role AS person_role,
        COUNT(*) OVER (PARTITION BY ci.person_id, ci.role_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ci.nr_order < 5
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        string_agg(DISTINCT k.keyword, ', ') AS keywords
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
    DISTINCT rt.title,
    rt.production_year,
    p.person_role,
    COALESCE(m.keywords, 'No Keywords') AS keywords,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = rt.title) AS info_count
FROM 
    RankedTitles rt
LEFT JOIN 
    PersonRoles p ON rt.title_rank = p.movie_id
LEFT JOIN 
    MoviesWithKeywords m ON rt.title = m.movie_id
WHERE 
    rt.production_year >= 1990 
    AND (p.role_count > 2 OR p.person_role IS NULL)
ORDER BY 
    rt.production_year DESC, rt.title;
