WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRankedMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        actor_count,
        actor_names,
        keywords,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM
        RankedMovies
)
SELECT
    tr.rank,
    tr.title,
    tr.production_year,
    tr.actor_count,
    tr.actor_names,
    tr.keywords
FROM
    TopRankedMovies tr
WHERE
    tr.rank <= 10
ORDER BY
    tr.rank;

This query first aggregates data to calculate the number of distinct actors and list their names for each movie. It also collects keywords associated with the movies in a string format. The aggregated results are ranked based on the number of actors, and finally, it selects the top 10 ranked movies, displaying their title, production year, actor count, actor names, and associated keywords.
