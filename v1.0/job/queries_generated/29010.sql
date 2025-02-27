WITH MovieDetails AS (
    SELECT
        t.title AS MovieTitle,
        t.production_year AS Year,
        c.kind AS Genre,
        GROUP_CONCAT(DISTINCT ak.name) AS AlternateNames,
        GROUP_CONCAT(DISTINCT co.name) AS ProductionCompanies,
        GROUP_CONCAT(DISTINCT k.keyword) AS Keywords
    FROM
        aka_title AS t
    JOIN
        kind_type AS k ON t.kind_id = k.id
    JOIN
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN
        company_name AS co ON mc.company_id = co.id
    JOIN
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN
        cast_info AS ci ON t.id = ci.movie_id
    LEFT JOIN
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY
        t.id, t.title, t.production_year, c.kind
)

SELECT
    MovieDetails.MovieTitle,
    MovieDetails.Year,
    MovieDetails.Genre,
    MovieDetails.AlternateNames,
    MovieDetails.ProductionCompanies,
    MovieDetails.Keywords
FROM
    MovieDetails
ORDER BY
    MovieDetails.Year DESC, MovieDetails.MovieTitle;
