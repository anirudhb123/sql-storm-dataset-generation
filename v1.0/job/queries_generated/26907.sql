WITH MovieStats AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS also_known_as,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_notes_count
    FROM title t
    JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    GROUP BY t.id, t.title, t.production_year
),

CompanyStats AS (
    SELECT
        m.id AS movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies_involved,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies m
    JOIN company_name cn ON m.company_id = cn.id
    JOIN company_type ct ON m.company_type_id = ct.id
    GROUP BY m.movie_id
),

FinalStats AS (
    SELECT
        ms.movie_title,
        ms.production_year,
        ms.actor_count,
        ms.keyword_count,
        ms.also_known_as,
        ms.cast_notes_count,
        cs.companies_involved,
        cs.company_types
    FROM MovieStats ms
    LEFT JOIN CompanyStats cs ON ms.movie_title = cs.movie_id
)

SELECT
    fs.movie_title,
    fs.production_year,
    fs.actor_count,
    fs.keyword_count,
    fs.also_known_as,
    fs.cast_notes_count,
    fs.companies_involved,
    fs.company_types
FROM FinalStats fs
ORDER BY fs.production_year DESC, fs.actor_count DESC;
