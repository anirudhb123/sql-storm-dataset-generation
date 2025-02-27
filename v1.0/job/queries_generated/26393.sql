WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS title_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CastRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(DISTINCT c.person_id) AS role_count
    FROM 
        cast_info c
    INNER JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    rt.company_count,
    rt.keyword_count,
    cr.role,
    cr.role_count,
    mi.movie_details
FROM 
    RankedTitles rt
LEFT JOIN 
    CastRoles cr ON rt.id = cr.movie_id
LEFT JOIN 
    MovieInfo mi ON rt.id = mi.movie_id
WHERE 
    rt.title_rank <= 10
ORDER BY 
    rt.production_year DESC, rt.keyword_count DESC;
