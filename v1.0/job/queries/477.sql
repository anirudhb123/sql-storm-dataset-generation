WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
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
        COUNT(DISTINCT kw.keyword) AS total_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    cs.total_companies,
    cs.company_names,
    ks.total_keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyStats cs ON rm.title = (SELECT title FROM aka_title WHERE id = cs.movie_id)
LEFT JOIN 
    KeywordStats ks ON rm.title = (SELECT title FROM aka_title WHERE id = ks.movie_id)
WHERE 
    rm.rank_per_year = 1
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC;
