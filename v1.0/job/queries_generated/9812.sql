WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title AS a
    JOIN 
        complete_cast AS cc ON a.id = cc.movie_id
    JOIN 
        cast_info AS ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name AS ak ON ak.person_id = ci.person_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        a.title, a.production_year, a.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.actor_names,
    ci.company_count,
    ci.companies
FROM 
    RankedMovies AS rm
LEFT JOIN 
    CompanyInfo AS ci ON rm.movie_id = ci.movie_id
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 50;
