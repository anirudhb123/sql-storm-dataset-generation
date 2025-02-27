WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) as rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword k ON a.movie_id = k.movie_id
    WHERE 
        k.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE 'Drama%')
),
CompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(cc.company_count, 0) AS company_count,
    (SELECT COUNT(DISTINCT ci.person_id) 
     FROM cast_info ci 
     WHERE ci.movie_id = rm.movie_id) AS actor_count,
    (SELECT STRING_AGG(DISTINCT ak.name, ', ') 
     FROM aka_name ak 
     WHERE ak.person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = rm.movie_id)) AS actor_names
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyCount cc ON rm.movie_id = cc.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title;
