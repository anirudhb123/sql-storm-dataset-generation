WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
PopularActors AS (
    SELECT 
        ak.name,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        RankedMovies rm ON c.movie_id = rm.movie_id
    WHERE 
        rm.rank <= 5
    GROUP BY 
        ak.name
),
MovieCompanies AS (
    SELECT 
        a.title,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        a.id, a.title
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    COALESCE(pa.movie_count, 0) AS popular_actor_count,
    COALESCE(mc.companies, 'No Companies') AS associated_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularActors pa ON rm.actor_count = pa.movie_count
LEFT JOIN 
    MovieCompanies mc ON rm.title = mc.title
WHERE 
    rm.actor_count > 0
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC;
