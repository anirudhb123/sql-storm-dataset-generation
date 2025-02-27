WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cn.name) AS company_row
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
KeywordInfo AS (
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
DetailedMovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(kw.keywords, 'No keywords') AS keywords,
        COALESCE(g.company_names, 'No companies') AS companies,
        COALESCE(cr.role, 'No roles') AS roles
    FROM 
        title t
    LEFT JOIN 
        KeywordInfo kw ON t.id = kw.movie_id
    LEFT JOIN (
        SELECT 
            movie_id,
            STRING_AGG(company_name || ' (' || company_type || ')', '; ') AS company_names
        FROM 
            MovieCompanyInfo
        GROUP BY 
            movie_id
    ) g ON t.id = g.movie_id
    LEFT JOIN (
        SELECT 
            movie_id,
            STRING_AGG(role || ' (' || role_count || ')', '; ') AS role
        FROM 
            CastRoles
        GROUP BY 
            movie_id
    ) cr ON t.id = cr.movie_id
)
SELECT 
    dmi.title,
    dmi.production_year,
    dmi.keywords,
    dmi.companies,
    dmi.roles
FROM 
    DetailedMovieInfo dmi
WHERE 
    EXISTS (
        SELECT 1
        FROM aka_title ak
        WHERE ak.movie_id = dmi.movie_id
        AND ak.production_year = dmi.production_year
    )
AND (
    SELECT COUNT(*)
    FROM complete_cast cc
    WHERE cc.movie_id = dmi.movie_id
) > 1
AND dmi.production_year > 2000
ORDER BY 
    dmi.production_year DESC, dmi.title ASC;

