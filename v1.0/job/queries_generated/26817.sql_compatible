
WITH movie_data AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases,
        COALESCE(STRING_AGG(DISTINCT cn.name, ', '), 'No Companies') AS companies,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM aka_title mt
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY mt.id, mt.title, mt.production_year
),
keyword_data AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
info_data AS (
    SELECT
        mi.movie_id,
        STRING_AGG(DISTINCT it.info || ': ' || mi.info, '; ') AS additional_info
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aliases,
    md.companies,
    md.cast_count,
    kd.keywords,
    id.additional_info
FROM movie_data md
LEFT JOIN keyword_data kd ON md.movie_id = kd.movie_id
LEFT JOIN info_data id ON md.movie_id = id.movie_id
WHERE md.production_year BETWEEN 1990 AND 2023
ORDER BY md.production_year DESC, md.cast_count DESC;
