
WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year, 
        ak.name AS actor_name, 
        COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM 
        aka_title at
    JOIN 
        complete_cast cc ON at.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_companies mc ON at.id = mc.movie_id
    WHERE 
        at.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        at.title, at.production_year, ak.name
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        actor_name, 
        production_company_count,
        RANK() OVER (PARTITION BY production_year ORDER BY production_company_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    production_year, 
    title, 
    actor_name, 
    production_company_count
FROM 
    TopMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year, rank;
