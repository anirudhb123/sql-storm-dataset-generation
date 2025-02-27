WITH RankedTitles AS (
    SELECT
        title.id AS title_id,
        title.title AS title_name,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id) AS title_rank,
        COUNT(*) OVER (PARTITION BY title.production_year) AS title_count
    FROM
        title
    WHERE
        title.production_year BETWEEN 1990 AND 2020
),
CastDetails AS (
    SELECT
        cast_info.movie_id,
        COUNT(DISTINCT char_name.imdb_id) AS unique_actors,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS actor_names
    FROM
        cast_info
    JOIN
        aka_name ON cast_info.person_id = aka_name.person_id
    JOIN
        char_name ON aka_name.id = char_name.id
    GROUP BY
        cast_info.movie_id
),
MovieKeywords AS (
    SELECT
        movie_keyword.movie_id,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords
    FROM
        movie_keyword
    JOIN
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY
        movie_keyword.movie_id
)
SELECT
    rt.title_id,
    rt.title_name,
    rt.production_year,
    COALESCE(cd.unique_actors, 0) AS unique_actor_count,
    COALESCE(cd.actor_names, 'N/A') AS actor_names,
    COALESCE(mk.keywords, 'No keywords') AS movie_keywords,
    CASE
        WHEN rt.title_count > 10 THEN 'Popular Year'
        WHEN rt.title_count BETWEEN 5 AND 10 THEN 'Moderate Year'
        ELSE 'Less Known'
    END AS year_popularity_status
FROM
    RankedTitles rt
LEFT JOIN
    CastDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN
    MovieKeywords mk ON rt.title_id = mk.movie_id
WHERE
    rt.title_rank <= 5 OR cd.unique_actors IS NOT NULL
ORDER BY
    rt.production_year DESC, rt.title_id ASC;
