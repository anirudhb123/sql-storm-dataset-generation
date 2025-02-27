WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        SUM(CASE WHEN ct.kind = 'Production' THEN 1 ELSE 0 END) AS production_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    ci.companies,
    ci.production_count,
    COALESCE(CAST(NULLIF(ci.production_count, 0) AS TEXT), 'No Production Companies') AS production_count_summary,
    CASE 
        WHEN rm.actor_count > 10 THEN 'Ensemble Cast'
        ELSE 'Standard Cast' 
    END AS cast_size
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyInfo ci ON rm.title = ci.title
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;

WITH MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    t.title,
    t.production_year,
    CASE 
        WHEN mk.keywords IS NOT NULL THEN mk.keywords
        ELSE 'No Keywords Available' 
    END AS keywords
FROM 
    title t
LEFT JOIN 
    MovieKeywords mk ON t.id = mk.movie_id
WHERE 
    t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'Feature Film')
ORDER BY 
    t.production_year DESC;
