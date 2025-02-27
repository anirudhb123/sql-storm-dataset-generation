WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER(PARTITION BY m.production_year ORDER BY m.id) AS rank
    FROM 
        title m
    WHERE 
        m.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(cn.name) AS companies_list
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.rank,
    rm.title,
    rm.production_year,
    ta.name AS actor_name,
    mc.companies_list
FROM 
    RankedMovies rm
JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
JOIN 
    TopActors ta ON ci.person_id = ta.person_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.rank;
