WITH MovieRanks AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        DENSE_RANK() OVER (PARTITION BY YEAR(mt.production_year) ORDER BY mt.id) AS year_rank,
        COUNT(DISTINCT mk.keyword_id) OVER (PARTITION BY mt.id) AS keyword_count
    FROM
        aka_title mt
    LEFT JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE
        mt.production_year IS NOT NULL
),
NotableNames AS (
    SELECT
        a.id AS person_id,
        a.name,
        COALESCE(char.name, 'Unknown Character') AS char_name,
        RANK() OVER (PARTITION BY a.id ORDER BY a.name DESC) AS name_rank
    FROM
        aka_name a
    LEFT JOIN
        char_name char ON a.person_id = char.imdb_id
    WHERE
        a.name IS NOT NULL
),
MovieDetails AS (
    SELECT
        mv.movie_id,
        mv.title,
        mv.production_year,
        COALESCE(cn.name, 'No Company') AS production_company,
        COALESCE(ct.kind, 'Unknown Type') AS company_type,
        RANK() OVER (PARTITION BY mv.movie_id ORDER BY mv.id) AS movie_rank
    FROM
        MovieRanks mv
    LEFT JOIN
        movie_companies mc ON mv.movie_id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        company_type ct ON mc.company_type_id = ct.id
    WHERE
        mv.keyword_count > 3
)
SELECT
    md.title,
    md.production_year,
    nn.name AS actor_name,
    nn.char_name,
    md.production_company,
    md.company_type,
    md.movie_rank,
    COALESCE(industry_info.info, 'No Info') AS additional_info
FROM
    MovieDetails md
JOIN
    cast_info ci ON md.movie_id = ci.movie_id
JOIN
    NotableNames nn ON ci.person_id = nn.person_id
LEFT JOIN
    movie_info industry_info ON md.movie_id = industry_info.movie_id AND industry_info.info_type_id = 1
WHERE
    md.movie_rank <= 5
    AND (nn.name_rank = 1 OR nn.name IS NULL)
    AND md.production_year >= 2000
ORDER BY
    md.production_company NULLS LAST,
    md.production_year DESC,
    md.title ASC;


This SQL query leverages several advanced SQL constructs, including CTEs, window functions, outer joins, and complicated predicates. It benchmarks movie production data, extracting data regarding notable roles, co-productions, and additional movie information, with a focus on certain conditions and ranks.
