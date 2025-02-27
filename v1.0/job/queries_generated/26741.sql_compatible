
WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT tc.kind, ', ') AS company_types,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM
        aka_title AS t
    LEFT JOIN
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN
        aka_name AS a ON c.person_id = a.person_id
    LEFT JOIN
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name AS co ON mc.company_id = co.id
    LEFT JOIN
        company_type AS tc ON mc.company_type_id = tc.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year
),
info_collected AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.cast_names,
        md.keywords,
        COUNT(mi.id) AS info_count,
        STRING_AGG(DISTINCT i.info, '; ') AS additional_info
    FROM
        movie_details AS md
    LEFT JOIN
        movie_info AS mi ON md.movie_id = mi.movie_id
    LEFT JOIN
        info_type AS i ON mi.info_type_id = i.id
    GROUP BY
        md.movie_id, md.title, md.production_year, md.cast_count, md.cast_names, md.keywords
)
SELECT 
    ic.title,
    ic.production_year,
    ic.cast_count,
    ic.cast_names,
    ic.keywords,
    ic.info_count,
    ic.additional_info
FROM
    info_collected AS ic
ORDER BY 
    ic.production_year DESC, 
    ic.cast_count DESC
LIMIT 100;
