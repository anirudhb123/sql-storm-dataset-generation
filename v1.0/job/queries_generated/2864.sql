WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY t.id) AS actor_count,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS total_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    COALESCE(cs.total_companies, 0) AS total_companies,
    COALESCE(cs.companies_names, 'No Companies') AS companies_names,
    COALESCE(ks.total_keywords, 0) AS total_keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyStats cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    KeywordStats ks ON rm.movie_id = ks.movie_id
WHERE 
    rm.actor_count > 2
  AND 
    rm.production_year > 2000
ORDER BY 
    rm.production_year DESC, rm.title;
