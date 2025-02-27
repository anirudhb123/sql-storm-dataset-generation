WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cp.kind) AS company_types
    FROM
        title t
    LEFT JOIN
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_type cp ON mc.company_type_id = cp.id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY
        t.id,
        t.title,
        t.production_year
),
TitleStatistics AS (
    SELECT
        production_year,
        COUNT(*) AS total_movies,
        COUNT(DISTINCT movie_id) AS unique_movies,
        AVG(LENGTH(title)) AS avg_title_length,
        MAX(CASE WHEN CHAR_LENGTH(keyword) > 5 THEN 1 ELSE 0 END) AS has_long_keywords
    FROM
        MovieDetails
    GROUP BY
        production_year
)
SELECT
    year.production_year,
    year.total_movies,
    year.unique_movies,
    year.avg_title_length,
    CASE WHEN year.has_long_keywords > 0 THEN 'Yes' ELSE 'No' END AS has_long_keywords,
    movie_stats.cast_names,
    movie_stats.keywords,
    movie_stats.company_types
FROM
    TitleStatistics year
JOIN
    MovieDetails movie_stats ON movie_stats.production_year = year.production_year
ORDER BY
    year.production_year DESC;
