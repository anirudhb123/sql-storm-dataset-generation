WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_in_year,
        COUNT(mk.keyword_id) AS keyword_count,
        COALESCE(cn.country_code, 'N/A') AS country_code
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        t.id, t.title, t.production_year, cn.country_code
),

TopMovies AS (
    SELECT
        rm.*,
        CASE 
            WHEN rm.rank_in_year = 1 THEN 'Top Title'
            ELSE 'Not Top Title'
        END AS title_rank
    FROM
        RankedMovies rm
    WHERE
        rm.rank_in_year <= 3
)

SELECT
    tm.title,
    tm.production_year,
    tm.country_code,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = tm.movie_id) AS actor_count,
    (SELECT STRING_AGG(DISTINCT a.name, ', ') 
     FROM cast_info ci 
     JOIN aka_name a ON ci.person_id = a.person_id
     WHERE ci.movie_id = tm.movie_id
     AND a.name IS NOT NULL) AS actors
FROM
    TopMovies tm
WHERE
    tm.country_code IS NOT NULL
    AND tm.keyword_count > 0
    AND EXISTS (
        SELECT 1
        FROM movie_info mi 
        WHERE mi.movie_id = tm.movie_id
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
    )
ORDER BY
    RANDOM() 
LIMIT 10;

-- Return the movie titles, production years, and actor counts for the top-ranked movies of the specified years,
-- along with their country codes and a list of actors, ensuring only those that have box office info and
-- are associated with valid keywords.
