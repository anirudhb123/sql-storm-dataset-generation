
WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        c.role_id,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        a.name IS NOT NULL
),
PopularMovies AS (
    SELECT 
        t.title,
        COUNT(cc.id) AS cast_count
    FROM 
        title t
    JOIN 
        cast_info cc ON t.id = cc.movie_id
    GROUP BY 
        t.title
    HAVING 
        COUNT(cc.id) > 5
),
MovieWithKeywords AS (
    SELECT 
        m.title,
        k.keyword
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year > 2000
)
SELECT 
    am.actor_name,
    am.movie_title,
    am.production_year,
    pm.cast_count,
    mk.keyword
FROM 
    ActorMovies am
JOIN 
    PopularMovies pm ON am.movie_title = pm.title
LEFT JOIN 
    MovieWithKeywords mk ON am.movie_title = mk.title
WHERE 
    am.movie_rank <= 3
ORDER BY 
    am.actor_name, am.production_year DESC;
