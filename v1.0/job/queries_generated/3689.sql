WITH MovieInfo AS (
    SELECT
        title.title AS movie_title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS actor_count,
        AVG(CASE WHEN movie_info.info IS NOT NULL THEN LENGTH(movie_info.info) ELSE 0 END) AS avg_info_length
    FROM
        title
    LEFT JOIN
        movie_info ON title.id = movie_info.movie_id
    LEFT JOIN
        cast_info ON title.id = cast_info.movie_id
    WHERE
        title.production_year IS NOT NULL
    GROUP BY
        title.id
),
CompanyCount AS (
    SELECT
        movie_id,
        COUNT(DISTINCT company_name.id) AS total_companies
    FROM
        movie_companies
    JOIN
        company_name ON movie_companies.company_id = company_name.id
    GROUP BY
        movie_id
),
Ranking AS (
    SELECT
        movie_title,
        production_year,
        actor_count,
        total_companies,
        RANK() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS actor_rank
    FROM
        MovieInfo
    LEFT JOIN
        CompanyCount ON MovieInfo.id = CompanyCount.movie_id
)
SELECT
    movie_title,
    production_year,
    actor_count,
    total_companies,
    actor_rank
FROM
    Ranking
WHERE
    (total_companies IS NULL OR total_companies > 5)
    AND actor_count > (
        SELECT AVG(actor_count) FROM Ranking
    )
ORDER BY
    production_year, actor_rank;
