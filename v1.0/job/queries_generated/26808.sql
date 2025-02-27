WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        actors,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rn
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.actors
FROM 
    TopMovies tm
WHERE 
    tm.rn <= 10
ORDER BY 
    tm.actor_count DESC;

This SQL query benchmarks string processing by aggregating data from several tables to find the top 10 movies produced since 2000 with the highest number of unique actors, along with their titles and associated keywords. The use of `STRING_AGG` allows for efficient string processing and showcases the ability to handle and manipulate textual data.
