
WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(c.id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    GROUP BY
        t.title, t.production_year
),
MovieDetails AS (
    SELECT
        m.title,
        m.production_year,
        COALESCE(m.num_cast_members, 0) AS num_cast_members,
        COALESCE(info.info, 'No additional info') AS additional_info,
        m.rank_by_cast
    FROM
        RankedMovies m
    LEFT JOIN
        movie_info info ON m.title = info.info AND m.production_year = (SELECT MAX(production_year) FROM aka_title WHERE title = m.title)
)
SELECT
    md.title,
    md.production_year,
    md.num_cast_members,
    md.additional_info,
    COALESCE(k.keyword, 'No keyword') AS movie_keyword,
    p.name AS person_name
FROM
    MovieDetails md
LEFT JOIN
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = md.title AND production_year = md.production_year LIMIT 1)
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = md.title AND production_year = md.production_year LIMIT 1)
LEFT JOIN
    aka_name p ON cc.subject_id = p.person_id
WHERE
    md.rank_by_cast <= 5 OR md.production_year IS NULL
ORDER BY
    md.production_year DESC, md.num_cast_members DESC;
