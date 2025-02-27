WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        COUNT(DISTINCT mi.id) AS info_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id
),
ActorCount AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
AkaCounts AS (
    SELECT 
        a.movie_id, 
        COUNT(DISTINCT a.person_id) AS aka_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS total_actors,
    COALESCE(ak.aka_count, 0) AS total_akas,
    rm.info_count AS total_info,
    rm.company_count AS total_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCount ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    AkaCounts ak ON rm.movie_id = ak.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC
LIMIT 100;
