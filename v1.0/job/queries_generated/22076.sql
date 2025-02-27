WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS actor_rank,
        COUNT(ci.person_id) AS actor_count
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        actor_rank
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 5
),

MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),

CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
)

SELECT 
    tm.title AS MovieTitle,
    tm.production_year AS ProductionYear,
    tm.actor_count AS ActorCount,
    COALESCE(mk.keywords, 'No Keywords') AS Keywords,
    COALESCE(ci.companies, 'No Companies') AS Companies,
    ci.company_type AS CompanyType
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title_id = mk.movie_id
LEFT JOIN 
    CompanyInfo ci ON tm.title_id = ci.movie_id
WHERE 
    tm.production_year >= 2000
    AND (tm.actor_count IS NOT NULL OR mk.keywords IS NOT NULL)
ORDER BY 
    tm.production_year DESC, 
    tm.actor_rank ASC;
