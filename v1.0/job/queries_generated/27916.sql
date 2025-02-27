WITH RankedMovies AS (
    SELECT
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ak.imdb_index AS actor_index,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM
        aka_title AS at
    JOIN
        cast_info AS ci ON at.id = ci.movie_id
    JOIN
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE
        at.production_year >= 2000  -- Focus on movies from the year 2000 onwards
        AND ak.name IS NOT NULL      -- Exclude entries with NULL actor names
),
ActorCounts AS (
    SELECT
        movie_title,
        production_year,
        COUNT(actor_name) AS actor_count
    FROM
        RankedMovies
    GROUP BY
        movie_title, production_year
),
MovieDetails AS (
    SELECT
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        ac.actor_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY ac.actor_count DESC) AS rank_by_actor_count
    FROM
        title AS m
    JOIN
        movie_keyword AS mk ON m.id = mk.movie_id
    JOIN
        keyword AS k ON mk.keyword_id = k.id
    JOIN
        ActorCounts AS ac ON m.title = ac.movie_title AND m.production_year = ac.production_year
)
SELECT
    md.movie_title,
    md.production_year,
    md.movie_keyword,
    md.actor_count
FROM
    MovieDetails AS md
WHERE
    md.rank_by_actor_count <= 5  -- Retrieve top 5 movies by actor count each year
ORDER BY
    md.production_year, md.actor_count DESC;
