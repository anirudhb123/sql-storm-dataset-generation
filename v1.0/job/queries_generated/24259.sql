WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_in_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

ActorRoles AS (
    SELECT 
        a.person_id,
        a.name,
        c.role_id,
        r.role,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        a.person_id, a.name, c.role_id, r.role
),

MoviesWithActorSummary AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.name AS actor_name,
        ar.role AS actor_role,
        ar.movie_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON EXISTS (
            SELECT 1 FROM cast_info ci
            WHERE ci.movie_id = rm.movie_id AND ci.person_id = ar.person_id
        )
)

SELECT 
    m.title, 
    m.production_year, 
    COALESCE(m.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(m.actor_role, 'Unknown Role') AS actor_role,
    m.movie_count,
    CASE 
        WHEN m.movie_count IS NULL THEN 'Zero Movies'
        WHEN m.movie_count > 10 THEN 'Prolific Actor'
        ELSE 'Regular Actor' 
    END AS actor_status
FROM 
    MoviesWithActorSummary m
WHERE 
    m.production_year BETWEEN 1990 AND 2020
ORDER BY 
    m.production_year DESC, 
    m.title ASC;

-- Additionally retrieve movies with keywords that might be noisy (NULLs or improbable titles)
SELECT 
    DISTINCT t.title, 
    k.keyword 
FROM 
    title t
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.title NOT LIKE '%[a-zA-Z]%' 
    OR k.keyword IS NULL 
    OR k.keyword LIKE '%bizarre%'
ORDER BY 
    t.title;

-- Use a correlated subquery to find movies by actors who starred in more than 5 films with 'drama' or 'thriller' as keywords
SELECT 
    DISTINCT ar.actor_name,
    (SELECT COUNT(*) 
     FROM cast_info ci 
     JOIN movie_keyword mk ON ci.movie_id = mk.movie_id
     JOIN keyword k ON mk.keyword_id = k.id
     WHERE ci.person_id = ar.person_id 
     AND k.keyword IN ('drama', 'thriller')) AS drama_thriller_count
FROM 
    ActorRoles ar
WHERE 
    (SELECT COUNT(*) 
     FROM cast_info ci 
     WHERE ci.person_id = ar.person_id) > 5
AND drama_thriller_count > 0;

-- Finally, aggregate titles per production year to showcase trends
SELECT 
    production_year,
    COUNT(DISTINCT title) AS titles_count,
    STRING_AGG(DISTINCT title, ', ') AS all_titles
FROM 
    aka_title
GROUP BY 
    production_year
HAVING 
    COUNT(DISTINCT title) > 10
ORDER BY 
    production_year DESC;
