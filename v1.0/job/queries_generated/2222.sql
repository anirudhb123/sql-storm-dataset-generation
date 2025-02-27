WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
PersonRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS role_count,
        STRING_AGG(DISTINCT ct.kind) AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type ct ON ci.role_id = ct.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    mk.keywords,
    pr.role_count,
    pr.roles,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = rt.title_id AND mi.note IS NULL) AS info_count,
    COALESCE(NULLIF(LAG(rt.production_year) OVER (ORDER BY rt.production_year), rt.production_year), 'No Previous Year') AS prev_year_status
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieKeywords mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    PersonRoles pr ON rt.title_id = pr.movie_id
ORDER BY 
    rt.production_year DESC, rt.title ASC;
