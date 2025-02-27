WITH RankedMovies AS (
    SELECT
        mt.title AS movie_title,
        mt.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS year_rank
    FROM
        aka_title mt
        JOIN cast_info ci ON mt.id = ci.movie_id
        JOIN aka_name ak ON ci.person_id = ak.person_id
        LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    WHERE
        mt.production_year IS NOT NULL
    GROUP BY
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT
        movie_title,
        production_year,
        actor_names,
        company_count
    FROM
        RankedMovies
    WHERE
        year_rank <= 5
)
SELECT
    tm.movie_title,
    tm.production_year,
    tm.actor_names,
    COALESCE(NULLIF(tm.company_count, 0), 'No companies') AS company_count
FROM
    TopMovies tm
WHERE
    EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title LIMIT 1)
          AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget' LIMIT 1)
          AND mi.info NOT LIKE '%$%'
    )
ORDER BY
    tm.production_year DESC, 
    tm.company_count DESC;
