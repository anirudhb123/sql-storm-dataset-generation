WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), ActorDetails AS (
    SELECT 
        ak.person_id,
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
    HAVING 
        COUNT(ci.movie_id) > 5
), MovieActorInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        ad.actor_name,
        ad.movie_count
    FROM 
        RankedMovies rm
    JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    JOIN 
        ActorDetails ad ON ci.person_id = ad.person_id
    WHERE 
        rm.year_rank <= 10
), MovieCompanyInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        GROUP_CONCAT(DISTINCT c.name) AS companies
    FROM 
        MovieActorInfo m
    JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        m.movie_id, m.title
)
SELECT 
    m.title,
    m.production_year,
    ma.actor_name,
    ma.movie_count,
    mc.companies
FROM 
    MovieActorInfo ma
JOIN 
    MovieCompanyInfo mc ON ma.movie_id = mc.movie_id
ORDER BY 
    m.production_year DESC, ma.movie_count DESC;
