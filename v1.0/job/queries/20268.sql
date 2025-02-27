WITH MovieDetails AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(ka.name, 'Unknown') AS aka_name,
        cm.name AS company_name,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM
        aka_title AS t
    LEFT JOIN aka_name AS ka ON t.id = ka.person_id
    LEFT JOIN movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN company_name AS cm ON mc.company_id = cm.id
    LEFT JOIN cast_info AS ci ON t.id = ci.movie_id
    LEFT JOIN movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN keyword AS k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id,
        t.title,
        t.production_year,
        t.kind_id,
        ka.name,
        cm.name
),
RankedMovieDetails AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC, keyword_count DESC) AS rank
    FROM
        MovieDetails
)
SELECT
    rmd.title_id,
    rmd.title,
    rmd.production_year,
    rmd.aka_name,
    rmd.company_name,
    rmd.cast_count,
    rmd.keyword_count,
    CASE
        WHEN rmd.cast_count IS NULL THEN 'No Cast'
        WHEN rmd.keyword_count IS NULL THEN 'No Keywords'
        ELSE 'Available'
    END AS data_availability,
    (SELECT COUNT(*) 
     FROM movie_info AS mi 
     WHERE mi.movie_id = rmd.title_id 
       AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Awards%')) AS awards_count,
    LAG(rmd.production_year) OVER (ORDER BY rmd.production_year) AS last_year
FROM
    RankedMovieDetails AS rmd
WHERE
    rmd.rank <= 5
ORDER BY
    rmd.production_year DESC, rmd.cast_count DESC;
