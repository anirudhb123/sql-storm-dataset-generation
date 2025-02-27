WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        r.title,
        r.production_year
    FROM 
        RankedMovies r
    WHERE 
        r.year_rank <= 5
),
ActorRoles AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        ARRAY_AGG(DISTINCT r.role ORDER BY r.role) AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.note IS NULL
    GROUP BY 
        c.person_id
),
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        ai.info AS actor_info,
        ar.movie_count,
        ar.roles
    FROM 
        aka_name ak
    JOIN 
        person_info ai ON ak.person_id = ai.person_id
    JOIN 
        ActorRoles ar ON ak.person_id = ar.person_id
)
SELECT 
    tm.title,
    tm.production_year,
    ai.actor_name,
    COALESCE(ai.actor_info, 'No Info') AS actor_info,
    ar.roles,
    CASE 
        WHEN ar.movie_count > 10 THEN 'Veteran'
        WHEN ar.movie_count BETWEEN 5 AND 10 THEN 'Experienced'
        ELSE 'Novice'
    END AS experience_level
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.production_year = ci.movie_id
LEFT JOIN 
    ActorInfo ai ON ci.person_id = ai.person_id
JOIN 
    ActorRoles ar ON ai.actor_name = ar.actor_name
WHERE 
    tm.production_year >= (SELECT MAX(production_year) FROM aka_title) - 10
ORDER BY 
    tm.production_year DESC, ar.movie_count DESC;
