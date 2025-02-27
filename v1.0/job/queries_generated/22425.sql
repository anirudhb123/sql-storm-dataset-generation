WITH RecursiveActorMovies AS (
    SELECT
        ca.person_id,
        ca.movie_id,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY ct.kind) AS actor_rank
    FROM
        cast_info ca
    JOIN
        comp_cast_type ct ON ca.person_role_id = ct.id
    WHERE
        ca.note IS NULL
),
AggregateMovies AS (
    SELECT
        am.person_id,
        COUNT(DISTINCT am.movie_id) AS movie_count,
        MAX(t.production_year) AS last_movie_year
    FROM
        RecursiveActorMovies am
    JOIN
        title t ON am.movie_id = t.id
    GROUP BY
        am.person_id
),
MovieGenres AS (
    SELECT
        m.movie_id,
        k.keyword AS genre
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        aka_title m ON mk.movie_id = m.id
),
ActorMoviesWithGenres AS (
    SELECT 
        aam.person_id,
        aam.movie_id,
        STRING_AGG(mg.genre, ', ' ORDER BY mg.genre) AS genres
    FROM
        AggregateMovies aam
    LEFT JOIN
        MovieGenres mg ON aam.movie_count > 5 AND aam.movie_id = mg.movie_id
    GROUP BY
        aam.person_id, aam.movie_id
)
SELECT
    aka.name,
    COALESCE(amm.movie_count, 0) AS total_movies,
    COALESCE(amm.last_movie_year, 'Unknown') AS last_movie,
    CASE
        WHEN amm.movie_count IS NULL THEN 'No Movies'
        WHEN amm.movie_count > 10 THEN 'Frequent Actor'
        WHEN amm.movie_count BETWEEN 5 AND 10 THEN 'Occasional Actor'
        ELSE 'Newbie'
    END AS actor_status,
    aam.genres
FROM
    aka_name aka
LEFT JOIN
    AggregateMovies amm ON aka.person_id = amm.person_id
LEFT JOIN
    ActorMoviesWithGenres aam ON aka.person_id = aam.person_id
WHERE
    aka.name NOT LIKE '%Test%' -- Excluding certain names
    AND (amm.movie_count IS NULL OR amm.last_movie_year >= 2000) -- Filter based on movie year
ORDER BY
    total_movies DESC NULLS LAST,
    aka.name;
