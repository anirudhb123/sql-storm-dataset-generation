WITH RECURSIVE ActorMovies AS (
    SELECT c.person_id, COUNT(DISTINCT m.id) AS movie_count
    FROM cast_info c
    JOIN aka_title m ON c.movie_id = m.id
    WHERE c.nr_order IS NOT NULL
    GROUP BY c.person_id
),
TopActors AS (
    SELECT a.person_id, a.movie_count
    FROM ActorMovies a
    ORDER BY a.movie_count DESC
    LIMIT 5
),
MovieDetails AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        avg(mk.keyword) AS avg_keyword_length,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN cast_info c ON c.movie_id = mt.id
    GROUP BY mt.id
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names,
        COUNT(DISTINCT ct.kind) AS company_types
    FROM movie_companies m
    JOIN company_name cn ON m.company_id = cn.id
    JOIN company_type ct ON m.company_type_id = ct.id
    GROUP BY m.movie_id
),
FinalOutput AS (
    SELECT DISTINCT
        m.movie_title,
        m.production_year,
        m.avg_keyword_length,
        m.total_cast,
        co.company_names,
        co.company_types,
        COALESCE(ta.movie_count, 0) AS actor_movies_count
    FROM MovieDetails m
    LEFT JOIN CompanyInfo co ON m.production_year = co.movie_id  -- Bizarre join condition
    LEFT JOIN TopActors ta ON m.total_cast > 5
    WHERE m.production_year IS NOT NULL
    AND (m.avg_keyword_length IS NULL OR m.avg_keyword_length > 2)
)
SELECT *
FROM FinalOutput
WHERE actor_movies_count IS NOT NULL OR company_types > 1
ORDER BY production_year DESC, total_cast DESC
LIMIT 100;

-- Investigate edge cases with NULLs, correlated subqueries, and outer joins.
