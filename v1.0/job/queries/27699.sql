
WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    LEFT JOIN
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN
        movie_keyword mw ON t.id = mw.movie_id
    LEFT JOIN
        keyword kw ON mw.keyword_id = kw.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year
),

movie_details AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.aliases,
        rm.keywords,
        COALESCE(mci.note, 'No additional notes') AS company_note,
        COALESCE(mci.company_id, 0) AS company_count
    FROM
        ranked_movies rm
    LEFT JOIN
        movie_companies mci ON rm.movie_id = mci.movie_id
)

SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.aliases,
    md.keywords,
    md.company_note,
    COUNT(DISTINCT mci.company_id) AS unique_companies
FROM
    movie_details md
LEFT JOIN
    movie_companies mci ON md.movie_id = mci.movie_id
GROUP BY
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.aliases,
    md.keywords,
    md.company_note
ORDER BY
    md.production_year DESC,
    md.cast_count DESC;
