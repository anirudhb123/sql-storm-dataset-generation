WITH RankedTitles AS (
    SELECT
        a.id AS aka_id,
        a.person_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM
        aka_name AS a
    JOIN
        cast_info AS c ON a.person_id = c.person_id
    JOIN
        title AS t ON c.movie_id = t.id
    WHERE
        t.title IS NOT NULL AND
        t.production_year IS NOT NULL
),
FilteredTitles AS (
    SELECT
        aka_id,
        person_id,
        aka_name,
        movie_title,
        production_year,
        kind_id
    FROM
        RankedTitles
    WHERE
        title_rank <= 3
),
MovieDetails AS (
    SELECT
        ft.*,
        kt.keyword AS related_keyword,
        ct.kind AS company_type,
        ic.info AS movie_info
    FROM
        FilteredTitles AS ft
    LEFT JOIN
        movie_keyword AS mk ON ft.movie_title = mk.movie_id
    LEFT JOIN
        keyword AS kt ON mk.keyword_id = kt.id
    LEFT JOIN
        movie_companies AS mc ON ft.movie_title = mc.movie_id
    LEFT JOIN
        company_type AS ct ON mc.company_type_id = ct.id
    LEFT JOIN
        movie_info AS ic ON ft.movie_title = ic.movie_id
)
SELECT
    person_id,
    aka_name,
    ARRAY_AGG(DISTINCT movie_title || ' (' || production_year || ')') AS movies,
    STRING_AGG(DISTINCT related_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_type, ', ') AS companies,
    STRING_AGG(DISTINCT movie_info, '; ') AS additional_info
FROM
    MovieDetails
GROUP BY
    person_id,
    aka_name
ORDER BY
    person_id;
