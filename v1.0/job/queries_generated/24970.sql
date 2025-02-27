WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_count_rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
RecentMovies AS (
    SELECT
        title,
        production_year,
        actor_count_rank
    FROM
        RankedMovies
    WHERE
        actor_count_rank <= 5
),
ExtendedMovieInfo AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        coalesce(mk.keyword, 'No Keywords') AS keyword,
        COALESCE(mi.info, 'No Info') AS additional_info,
        CASE
            WHEN rm.production_year = 2023 THEN 'New Release'
            WHEN rm.production_year < 1950 THEN 'Classic'
            ELSE 'Modern'
        END AS movie_era
    FROM
        RecentMovies rm
    LEFT JOIN
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN
        movie_info mi ON rm.movie_id = mi.movie_id
    WHERE
        mk.keyword IS NOT NULL OR mi.info IS NOT NULL
)
SELECT
    emi.title,
    emi.production_year,
    emi.keyword,
    emi.additional_info,
    emi.movie_era
FROM
    ExtendedMovieInfo emi
WHERE
    emi.movie_era IN ('New Release', 'Modern')
ORDER BY
    emi.production_year DESC,
    emi.title ASC
FETCH FIRST 10 ROWS ONLY;

-- Additional illustrative query with bizarre semantics
SELECT
    ak.name AS actor_name,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    STRING_AGG(DISTINCT tt.title, ', ') AS titles_contributed
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    aka_title tt ON ci.movie_id = tt.movie_id
WHERE
    ak.name IS NOT NULL
  AND
    ak.name NOT LIKE '%[0-9]%' -- Exclude names with numbers for an obscure search
GROUP BY
    ak.id
HAVING
    COUNT(ci.movie_id) > 2 OR ak.name IS NULL -- Includes NULL names for an unusual edge case
ORDER BY
    movie_count DESC
FETCH NEXT 5 ROWS ONLY;
