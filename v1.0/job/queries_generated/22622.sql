WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn,
        COUNT(*) OVER () AS total_movies
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorTitles AS (
    SELECT
        ak.person_id,
        ak.name,
        mu.title,
        mu.production_year
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    JOIN
        aka_title mu ON ci.movie_id = mu.id
    WHERE
        mu.production_year BETWEEN 2000 AND 2023
),
MovieCount AS (
    SELECT
        movie_id,
        COUNT(DISTINCT person_id) AS actor_count
    FROM
        cast_info
    GROUP BY
        movie_id
),
TitleWithActorCount AS (
    SELECT
        m.id AS movie_id,
        m.title,
        mc.actor_count
    FROM
        aka_title m
    LEFT JOIN
        MovieCount mc ON m.id = mc.movie_id
)
SELECT
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    r.total_movies,
    (SELECT COUNT(DISTINCT ci.person_id)
     FROM cast_info ci
     WHERE ci.movie_id = r.movie_id
     AND ci.note IS NULL) AS null_note_actor_count,
    CASE 
        WHEN COALESCE(ac.actor_count, 0) > 0 THEN 
            (SELECT COUNT(DISTINCT x.id)
             FROM aka_name x
             WHERE x.person_id IN (SELECT DISTINCT ci.person_id
                                   FROM cast_info ci
                                   WHERE ci.movie_id = r.movie_id
                                   AND ci.note IS NULL)
            )
        ELSE 0 
    END AS unique_actors_with_null_notes
FROM
    RankedMovies r
LEFT JOIN
    TitleWithActorCount ac ON r.movie_id = ac.movie_id
WHERE
    r.rn <= 10 AND -- Limit to first 10 movies per production year
    (r.production_year IN (SELECT DISTINCT production_year FROM aka_title)
    OR NOT EXISTS (SELECT 1 FROM aka_title WHERE production_year IS NOT NULL))
ORDER BY
    r.production_year,
    r.movie_id;
This SQL query features multiple advanced constructs, including Common Table Expressions (CTEs), window functions, outer joins, correlated subqueries, and complex predicates. It ranks movies by production year, counts actors associated with each title, checks for NULLs in the notes, and limits the resultant set based on specific criteria. It incorporates basic null logic and demonstrates corner cases by accounting for the case where no titles exist for the specified production years.
