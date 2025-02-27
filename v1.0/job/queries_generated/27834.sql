WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT a.id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title m
        LEFT JOIN cast_info ci ON m.id = ci.movie_id
        LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
        LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
        LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        actors,
        keywords,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.actor_count,
    m.actors AS main_actors,
    m.keywords AS keywords,
    g.kind AS genre
FROM 
    TopMovies m
    LEFT JOIN movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN company_type g ON mc.company_type_id = g.id
WHERE 
    m.rank <= 10
ORDER BY 
    m.actor_count DESC;

This query aggregates data to benchmark string processing by finding the top 10 movies by actor count, including related keywords and genres, showcasing the use of string aggregation and complex joins across multiple related tables.
