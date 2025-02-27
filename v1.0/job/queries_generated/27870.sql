WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names
    FROM
        aka_title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN aka_name c ON cc.subject_id = c.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    WHERE
        t.production_year >= 2000 AND
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
    GROUP BY
        t.id, t.title, t.production_year, k.keyword
),
MovieInfo AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.keyword,
        mi.info
    FROM
        MovieDetails md
    LEFT JOIN movie_info mi ON md.movie_id = mi.movie_id
    WHERE
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
)
SELECT
    mid.movie_id,
    mid.title,
    mid.production_year,
    mid.keyword,
    mid.info,
    COUNT(DISTINCT mid.movie_id) OVER (PARTITION BY mid.keyword) AS movie_count_by_keyword
FROM
    MovieInfo mid
ORDER BY
    mid.production_year DESC, 
    mid.movie_id ASC;
