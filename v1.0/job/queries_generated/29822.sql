WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),

ActorsInfo AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        ARRAY_AGG(DISTINCT ti.title) AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title ti ON ci.movie_id = ti.id
    GROUP BY 
        a.person_id, a.name
),

TopActors AS (
    SELECT 
        person_id,
        name,
        movies_count,
        ROW_NUMBER() OVER (ORDER BY movies_count DESC) AS rank
    FROM 
        ActorsInfo
)

SELECT 
    rm.title,
    rm.production_year,
    rm.keywords,
    rm.cast_count,
    ta.name AS top_actor_name,
    ta.movies_count AS top_actor_movies_count
FROM 
    RankedMovies rm
JOIN 
    TopActors ta ON ta.rank <= 5
WHERE 
    rm.rank_by_cast <= 10
ORDER BY 
    rm.cast_count DESC, rm.production_year DESC;
