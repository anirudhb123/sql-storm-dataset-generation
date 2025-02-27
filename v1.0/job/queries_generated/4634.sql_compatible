
WITH RankedMovies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM
        aka_title mt
    LEFT JOIN
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        company_count
    FROM
        RankedMovies
    WHERE
        rank <= 5
),
ActorDetails AS (
    SELECT
        ka.name AS actor_name,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes
    FROM
        aka_name ka
    INNER JOIN
        cast_info ci ON ka.person_id = ci.person_id
    INNER JOIN
        aka_title mt ON ci.movie_id = mt.id
    GROUP BY
        ka.name, mt.title, mt.production_year
)
SELECT
    tm.title,
    tm.production_year,
    tm.company_count,
    ad.actor_name,
    ad.actor_count,
    ad.has_notes
FROM
    TopMovies tm
LEFT JOIN
    ActorDetails ad ON tm.title = ad.title AND tm.production_year = ad.production_year
WHERE
    (tm.production_year BETWEEN 2000 AND 2020)
    AND (ad.actor_count IS NULL OR ad.actor_count > 2)
ORDER BY
    tm.production_year DESC, 
    tm.company_count DESC;
