WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT c.person_id) AS cast_ids,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
PersonDetails AS (
    SELECT 
        p.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_played,
        STRING_AGG(DISTINCT a1.name, ', ') AS co_actors
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        cast_info ci1 ON ci.movie_id = ci1.movie_id AND ci.person_id <> ci1.person_id
    LEFT JOIN 
        aka_name a1 ON ci1.person_id = a1.person_id
    GROUP BY 
        p.person_id, a.name
),
TopMovies AS (
    SELECT 
        md.*,
        pd.actor_name,
        pd.cast_count,
        pd.co_actors
    FROM 
        MovieDetails md
    JOIN 
        PersonDetails pd ON pd.cast_ids && ARRAY[md.cast_ids]
    ORDER BY 
        md.production_year DESC, 
        md.cast_count DESC 
    LIMIT 10
)

SELECT 
    title AS "Movie Title",
    actor_name AS "Lead Actor",
    production_year AS "Year",
    cast_count AS "Number of Cast Members",
    movie_keyword AS "Keywords",
    co_actors AS "Co-Actors"
FROM 
    TopMovies;
