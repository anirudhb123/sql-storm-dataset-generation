
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        DENSE_RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_actors
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
), CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
), TitleKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    cs.company_count,
    cs.companies,
    tk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyStats cs ON rm.title = (SELECT at.title FROM aka_title at WHERE at.id = cs.movie_id)
LEFT JOIN 
    TitleKeywords tk ON rm.title = (SELECT at.title FROM aka_title at WHERE at.id = tk.movie_id)
WHERE 
    rm.rank_by_actors <= 5
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
