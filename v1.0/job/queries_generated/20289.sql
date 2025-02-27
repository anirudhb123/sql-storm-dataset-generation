WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(EXTRACT(YEAR FROM (CURRENT_DATE - INTERVAL '1 day' * mt.production_year)), 0) AS age,
        NULLIF(mt.season_nr, 0) AS is_seasonal,
        mt.kind_id,
        CAST(NULL AS text) AS parent_title
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        (SELECT title FROM aka_title WHERE id = ml.linked_movie_id) AS title,
        (SELECT production_year FROM aka_title WHERE id = ml.linked_movie_id) AS production_year,
        COALESCE(EXTRACT(YEAR FROM (CURRENT_DATE - INTERVAL '1 day' * (SELECT production_year FROM aka_title WHERE id = ml.linked_movie_id))), 0) AS age,
        NULLIF((SELECT season_nr FROM aka_title WHERE id = ml.linked_movie_id), 0) AS is_seasonal,
        (SELECT kind_id FROM aka_title WHERE id = ml.linked_movie_id) AS kind_id,
        mt.title AS parent_title
    FROM movie_link ml
    JOIN movie_hierarchy mt ON mt.movie_id = ml.movie_id
    WHERE ml.link_type_id IN (SELECT id FROM link_type WHERE link = 'sequel' OR link = 'prequel')
),
ranked_movies AS (
    SELECT 
        mh.*,
        ROW_NUMBER() OVER (PARTITION BY mh.kind_id ORDER BY mh.production_year DESC) AS rank_in_kind,
        COUNT(*) OVER (PARTITION BY mh.kind_id) AS total_in_kind
    FROM movie_hierarchy mh
),
filtered_movies AS (
    SELECT 
        rm.*,
        (age * total_in_kind) AS adjusted_age,
        CASE 
            WHEN is_seasonal IS NOT NULL THEN 'Seasonal'
            ELSE 'Standalone'
        END AS movie_type
    FROM ranked_movies rm
    WHERE adjusted_age > 0 AND total_in_kind > 3
)

SELECT 
    f.title,
    f.production_year,
    f.adjusted_age,
    f.movie_type,
    k.keyword,
    ARRAY_AGG(DISTINCT cn.name) AS companies,
    COUNT(DISTINCT ca.person_id) AS cast_count,
    SUM(CASE WHEN inf.info IS NOT NULL THEN 1 ELSE 0 END) AS info_filled_count
FROM filtered_movies f
LEFT JOIN movie_keyword mk ON f.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_companies mc ON f.movie_id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN cast_info ca ON f.movie_id = ca.movie_id
LEFT JOIN movie_info inf ON f.movie_id = inf.movie_id
GROUP BY f.title, f.production_year, f.adjusted_age, f.movie_type, k.keyword
ORDER BY f.adjusted_age DESC, f.production_year ASC
FETCH FIRST 10 ROWS ONLY;
