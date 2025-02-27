WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(mci.id) DESC) AS movie_rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        movie_companies mci ON t.id = mci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorsWithRoles AS (
    SELECT 
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(DISTINCT cc.movie_id) AS movies_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        a.name, r.role
)
SELECT 
    rm.title,
    rm.production_year,
    awr.actor_name,
    awr.role_name,
    awr.movies_count
FROM 
    RankedMovies rm
JOIN 
    ActorsWithRoles awr ON awr.movies_count > 5
WHERE 
    rm.movie_rank <= 10
ORDER BY 
    rm.production_year DESC, rm.title;
