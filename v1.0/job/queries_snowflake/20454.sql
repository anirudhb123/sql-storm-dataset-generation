
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyCounts cc ON rm.title_id = cc.movie_id
    WHERE 
        rm.rank = 1 
        AND rm.production_year > 2000
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        LISTAGG(DISTINCT rt.role, ', ') WITHIN GROUP (ORDER BY rt.role) AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(cr.roles, 'No roles') AS roles,
    COALESCE(fm.company_count, 0) AS company_count
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieKeywords mk ON fm.title_id = mk.movie_id
LEFT JOIN 
    CastRoles cr ON fm.title_id = cr.movie_id
WHERE 
    fm.company_count IS NOT NULL 
    AND (fm.production_year BETWEEN 2005 AND 2010 
         OR fm.production_year IS NULL)
ORDER BY 
    fm.production_year DESC, fm.title;
