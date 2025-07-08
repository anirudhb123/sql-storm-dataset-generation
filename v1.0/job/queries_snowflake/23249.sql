
WITH ranked_movies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(SUM(ci.nr_order), 0) AS total_cast,
        COUNT(DISTINCT mi.info_type_id) AS info_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COALESCE(SUM(ci.nr_order), 0) DESC) AS rn
    FROM
        aka_title m
    LEFT JOIN
        complete_cast cc ON cc.movie_id = m.id
    LEFT JOIN
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN
        movie_info mi ON mi.movie_id = m.id
    GROUP BY
        m.id, m.title, m.production_year
),
high_cast_movies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.total_cast,
        rm.info_count,
        'High' AS cast_level
    FROM
        ranked_movies rm
    WHERE
        rm.total_cast > 5
),
low_cast_movies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.total_cast,
        rm.info_count,
        'Low' AS cast_level
    FROM
        ranked_movies rm
    WHERE
        rm.total_cast <= 5
),
info_movie_summary AS (
    SELECT
        mv.movie_id,
        COUNT(DISTINCT mw.keyword_id) AS keyword_count,
        MAX(CASE WHEN it.info = 'Box Office' THEN mi.info END) AS box_office,
        MAX(CASE WHEN it.info = 'Genre' THEN mi.info END) AS genre,
        COUNT(DISTINCT mw.id) AS unique_keywords
    FROM
        aka_title mv
    LEFT JOIN
        movie_keyword mw ON mw.movie_id = mv.id
    LEFT JOIN
        movie_info mi ON mi.movie_id = mv.id
    LEFT JOIN
        info_type it ON it.id = mi.info_type_id
    GROUP BY
        mv.movie_id
)
SELECT 
    mhc.movie_id,
    mhc.title,
    mhc.total_cast,
    mls.box_office,
    mls.genre,
    mls.keyword_count,
    CASE 
        WHEN mhc.total_cast IS NULL THEN 'Unknown'
        WHEN mhc.info_count > 3 THEN 'Informative'
        ELSE 'Sparse'
    END AS info_density,
    mls.unique_keywords,
    mhc.cast_level
FROM 
    high_cast_movies mhc
LEFT JOIN 
    info_movie_summary mls ON mls.movie_id = mhc.movie_id

UNION ALL

SELECT 
    mlc.movie_id,
    mlc.title,
    mlc.total_cast,
    mls.box_office,
    mls.genre,
    mls.keyword_count,
    CASE 
        WHEN mlc.total_cast IS NULL THEN 'Unknown'
        WHEN mlc.info_count > 3 THEN 'Informative'
        ELSE 'Sparse'
    END AS info_density,
    mls.unique_keywords,
    mlc.cast_level
FROM 
    low_cast_movies mlc
LEFT JOIN 
    info_movie_summary mls ON mls.movie_id = mlc.movie_id;
