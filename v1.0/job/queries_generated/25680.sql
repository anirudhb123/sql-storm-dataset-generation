WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', ') AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
        GROUP_CONCAT(DISTINCT co.name ORDER BY co.name SEPARATOR ', ') AS companies
    FROM
        aka_title t
    LEFT JOIN
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name co ON mc.company_id = co.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year
),
movie_info_summary AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        COUNT(DISTINCT md.cast_names) AS total_cast,
        COUNT(DISTINCT md.keywords) AS total_keywords,
        COUNT(DISTINCT md.companies) AS total_companies
    FROM
        movie_details md
    GROUP BY
        md.movie_id, md.title, md.production_year
)
SELECT
    mis.movie_id,
    mis.title,
    mis.production_year,
    mis.total_cast,
    mis.total_keywords,
    mis.total_companies,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = mis.movie_id) AS additional_info_count
FROM
    movie_info_summary mis
ORDER BY
    mis.production_year DESC, mis.total_cast DESC, mis.title ASC;
