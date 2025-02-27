WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastCount AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies 
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA'
    GROUP BY 
        mc.movie_id
),
SubqueryKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    WHERE 
        mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%')
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cc.actor_count, 0) AS actor_count,
    COALESCE(cm.companies, 'No Companies') AS companies,
    COALESCE(sk.keyword_count, 0) AS action_keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CastCount cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
LEFT JOIN 
    SubqueryKeywords sk ON rm.movie_id = sk.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title ASC;
