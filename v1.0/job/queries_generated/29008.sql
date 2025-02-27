WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT c.character_name) AS characters,
        ARRAY_AGG(DISTINCT a.name) AS actors,
        COUNT(DISTINCT mc.company_id) AS production_company_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, k.keyword
),
RankedActors AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT cc.movie_id) AS movies_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    GROUP BY 
        a.name
    HAVING 
        movies_count > 5
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.movie_keyword,
    rm.characters,
    ra.actor_name,
    ra.movies_count,
    rm.production_company_count
FROM 
    RankedMovies rm
JOIN 
    RankedActors ra ON ra.actor_name = ANY(rm.actors)
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title, 
    ra.movies_count DESC;
