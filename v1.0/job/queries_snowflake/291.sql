
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.id) AS actor_count,
        DENSE_RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS rank_by_actor_count
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
HighActorMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_actor_count <= 5
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        AVG(CASE WHEN co.kind IS NOT NULL THEN 1 ELSE 0 END) AS has_distributed_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type co ON mc.company_type_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    hm.title,
    hm.production_year,
    cs.company_count,
    cs.has_distributed_companies,
    LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies_involved
FROM 
    HighActorMovies hm
LEFT JOIN 
    CompanyStats cs ON hm.title = (SELECT at.title FROM aka_title at WHERE at.id = cs.movie_id)
LEFT JOIN 
    movie_companies mc ON hm.title = (SELECT at.title FROM aka_title at WHERE at.id = mc.movie_id)
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    hm.title, hm.production_year, cs.company_count, cs.has_distributed_companies
HAVING 
    cs.company_count > 0 OR cs.has_distributed_companies = 1
ORDER BY 
    hm.production_year DESC, cs.company_count DESC;
