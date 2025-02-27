WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT c.kind, ', ') AS production_companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT mci.person_id) AS cast_count
    FROM
        aka_title t
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name c ON mc.company_id = c.id
    LEFT JOIN
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id
)
SELECT
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.actors,
    md.production_companies,
    md.keywords,
    md.cast_count,
    COALESCE(SUM(mi.info IS NOT NULL), 0) AS info_count
FROM
    movie_details md
LEFT JOIN
    movie_info mi ON md.movie_id = mi.movie_id
GROUP BY
    md.movie_id, md.movie_title, md.production_year, md.actors, md.production_companies, md.keywords, md.cast_count
ORDER BY
    md.production_year DESC, md.movie_title ASC;
