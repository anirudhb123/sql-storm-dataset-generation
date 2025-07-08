WITH RankedMovies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 END) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_role_id) DESC) AS rank
    FROM
        aka_title mt
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    WHERE
        mt.production_year >= 2000
    GROUP BY
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        actor_count
    FROM
        RankedMovies
    WHERE
        rank <= 5
),
CompanyCount AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count
    FROM
        movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY
        mc.movie_id
),
MovieDetails AS (
    SELECT
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.actor_count,
        COALESCE(cc.company_count, 0) AS company_count
    FROM
        TopMovies tm
    LEFT JOIN CompanyCount cc ON tm.movie_id = cc.movie_id
),
DescriptiveInfo AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_count,
        md.company_count,
        COALESCE(mi.info, 'No additional info') AS extra_info
    FROM
        MovieDetails md
    LEFT JOIN movie_info mi ON md.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
)
SELECT
    di.title,
    di.production_year,
    di.actor_count,
    di.company_count,
    di.extra_info,
    CASE
        WHEN di.actor_count > 10 THEN 'Blockbuster'
        ELSE 'Indie Film'
    END AS film_type,
    CASE
        WHEN di.extra_info IS NULL THEN 'Information not available'
        ELSE di.extra_info
    END AS informative_status,
    CONCAT('Film: ', di.title, ' (', di.production_year, ') has ', di.actor_count, ' actors and was produced by ', di.company_count, ' companies.') AS film_summary
FROM
    DescriptiveInfo di
WHERE
    di.production_year = (SELECT MAX(production_year) FROM MovieDetails)
ORDER BY
    di.actor_count DESC NULLS LAST;
