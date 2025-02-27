WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(cn.name || ' (' || ct.kind || ')') AS companies,
        COUNT(mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
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
)
SELECT 
    tm.title,
    tm.production_year,
    cd.companies,
    cd.company_count,
    mk.keywords,
    COALESCE(NULLIF(mk.keywords, ''), 'No keywords') AS keyword_status,
    (SELECT COUNT(id) FROM complete_cast WHERE movie_id = tm.movie_id) AS complete_cast_count,
    (SELECT COUNT(DISTINCT person_id) FROM cast_info ci WHERE ci.movie_id = tm.movie_id) AS distinct_actors_count,
    COUNT(DISTINCT ci.role_id) OVER (PARTITION BY tm.movie_id) AS distinct_roles_count
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyDetails cd ON tm.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
WHERE 
    (cd.company_count > 0 OR mk.keywords IS NOT NULL)
    AND (tm.production_year >= 2000 OR tm.production_year IS NULL)
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC
LIMIT 50;
