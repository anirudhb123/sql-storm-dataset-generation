WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
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
TopActors AS (
    SELECT 
        a.name,
        COUNT(DISTINCT m.movie_id) AS movie_count
    FROM 
        aka_name a
    INNER JOIN 
        cast_info c ON a.person_id = c.person_id
    INNER JOIN 
        RankedMovies m ON c.movie_id = m.movie_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT m.movie_id) > 5
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    a.name AS leading_actor,
    ac.actor_count,
    -1 * COALESCE(SUM(mk.keyword IS NOT NULL)::int, 0) AS non_null_keywords,
    CASE 
        WHEN ac.actor_count > 10 THEN 'Star-studded'
        WHEN ac.actor_count BETWEEN 5 AND 10 THEN 'Ensemble'
        ELSE 'Minimal Cast'
    END AS cast_description
FROM 
    RankedMovies r
LEFT JOIN 
    ActorCount ac ON r.movie_id = ac.movie_id
LEFT JOIN 
    TopActors a ON a.movie_count = ac.actor_count
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = r.movie_id
WHERE 
    r.rank <= 3
GROUP BY 
    r.movie_id, r.title, r.production_year, a.name, ac.actor_count
ORDER BY 
    r.production_year DESC, r.title ASC;
