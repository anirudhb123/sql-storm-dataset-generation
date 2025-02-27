WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        k.keyword AS movie_keyword,
        m.title AS movie_title
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_keyword mk ON ci.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON ci.movie_id = m.id
    WHERE 
        ci.role_id IS NOT NULL
), YearlyTopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
)
SELECT 
    y.movie_id,
    y.title,
    y.production_year,
    a.actor_name,
    STRING_AGG(DISTINCT ad.movie_keyword, ', ') AS keywords
FROM 
    YearlyTopMovies y
LEFT JOIN 
    ActorDetails a ON y.movie_id = a.movie_id
LEFT JOIN 
    aka_title at ON y.movie_id = at.id
GROUP BY 
    y.movie_id, y.title, y.production_year
ORDER BY 
    y.production_year DESC, y.title;
