WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC, t.title) AS rank
    FROM
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        r.role AS role_name,
        c.movie_id
    FROM 
        aka_name ak
    INNER JOIN 
        cast_info c ON ak.person_id = c.person_id
    INNER JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        ak.name IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
HighActorCountMovies AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.movie_id
    HAVING COUNT(DISTINCT c.person_id) > 5
)
SELECT
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(a.actor_name, 'Unknown Actor') AS top_actor,
    COALESCE(a.role_name, 'N/A') AS top_actor_role,
    COALESCE(k.keywords, '{}') AS keywords,
    CASE 
        WHEN hc.actor_count IS NOT NULL AND hc.actor_count > 10 THEN 'Highly Casted'
        ELSE 'Moderately Casted'
    END AS casting_category
FROM
    RankedMovies r
LEFT JOIN 
    ActorRoles a ON r.movie_id = a.movie_id
LEFT JOIN 
    MoviesWithKeywords k ON r.movie_id = k.movie_id
LEFT JOIN 
    HighActorCountMovies hc ON r.movie_id = hc.movie_id
WHERE 
    r.rank = 1
ORDER BY 
    r.production_year DESC, r.title;
