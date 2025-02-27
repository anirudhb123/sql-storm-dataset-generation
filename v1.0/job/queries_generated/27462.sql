WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS cast_rank
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        cast_info c ON t.id = c.movie_id
    WHERE
        t.production_year >= 2000
),
PopularMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        STRING_AGG(keyword, ', ') AS keywords
    FROM
        RankedMovies
    WHERE
        cast_rank <= 3  -- Only considering top 3 cast members based on order
    GROUP BY
        movie_id, title, production_year
),
CompanyInfo AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),
FinalBenchmark AS (
    SELECT
        pm.movie_id,
        pm.title,
        pm.production_year,
        pm.keywords,
        STRING_AGG(DISTINCT CONCAT(ci.company_name, ' (', ci.company_type, ')'), '; ') AS companies
    FROM
        PopularMovies pm
    LEFT JOIN
        CompanyInfo ci ON pm.movie_id = ci.movie_id
    GROUP BY
        pm.movie_id, pm.title, pm.production_year
)
SELECT
    movie_id,
    title,
    production_year,
    keywords,
    companies
FROM
    FinalBenchmark
ORDER BY
    production_year DESC, title;
