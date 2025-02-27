WITH RECURSIVE FilmFestivals AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS festival_level,
        COALESCE(m.year, 0) AS year,
        NULL AS parent_movie_id
    FROM title m
    WHERE production_year >= 2000

    UNION ALL

    SELECT 
        mf.movie_id AS movie_id,
        t.title AS movie_title,
        ff.festival_level + 1 AS festival_level,
        COALESCE(t.production_year, 0) AS year,
        ff.movie_id AS parent_movie_id
    FROM movie_link mf
    JOIN title t ON t.id = mf.linked_movie_id
    JOIN FilmFestivals ff ON ff.movie_id = mf.movie_id
    WHERE mf.link_type_id = 1  -- assuming '1' represents a specific type of link
),
RankedMovies AS (
    SELECT 
        f.movie_id,
        f.movie_title,
        f.year,
        RANK() OVER (PARTITION BY f.year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank_by_companies
    FROM FilmFestivals f
    LEFT JOIN movie_companies mc ON mc.movie_id = f.movie_id
    GROUP BY f.movie_id, f.movie_title, f.year
),
PopularActors AS (
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM cast_info ci
    JOIN aka_name a ON a.person_id = ci.person_id
    GROUP BY ci.person_id, a.name
    HAVING COUNT(ci.movie_id) > 5  -- actors with more than 5 movies
)
SELECT 
    DISTINCT rm.year,
    rm.movie_title,
    rm.rank_by_companies,
    pa.actor_name,
    pa.movie_count
FROM RankedMovies rm
JOIN movie_companies mc ON mc.movie_id = rm.movie_id
JOIN PopularActors pa ON pa.movie_count = (
        SELECT MAX(movie_count)
        FROM PopularActors
    )
WHERE rm.rank_by_companies <= 5
ORDER BY rm.year DESC, rm.rank_by_companies, pa.movie_count DESC;

-- This query benchmarks movies from the year 2000 onwards, ranks them by the number of companies associated with each movie, 
-- retrieves actors who have featured in more than 5 movies, 
-- and regroups the results to display movies with their top actor(s) based on the highest movie count.
