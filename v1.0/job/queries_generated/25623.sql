WITH RecursiveMovieInfo AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names
    FROM
        title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN name n ON a.person_id = n.imdb_id
    LEFT JOIN char_name cn ON n.imdb_id = cn.imdb_id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN person_info pi ON ci.person_id = pi.person_id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM
        movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
),
FinalBenchmark AS (
    SELECT
        r.movie_id,
        r.title,
        r.production_year,
        r.keywords,
        r.cast_names,
        COALESCE(m.companies, 'No Companies') AS companies
    FROM
        RecursiveMovieInfo r
    LEFT JOIN MovieCompanies m ON r.movie_id = m.movie_id
)
SELECT
    fb.movie_id,
    fb.title,
    fb.production_year,
    fb.keywords,
    fb.cast_names,
    fb.companies,
    LENGTH(fb.keywords) AS keyword_length,
    LENGTH(fb.cast_names) AS cast_names_length
FROM
    FinalBenchmark fb
ORDER BY
    fb.production_year DESC, 
    LENGTH(fb.keywords) DESC;
