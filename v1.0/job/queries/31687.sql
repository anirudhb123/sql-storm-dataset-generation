WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 5
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN ci.note IS NOT NULL THEN ci.person_id END) AS credited_cast
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
movie_genre AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
movie_info_agg AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.credited_cast, 0) AS credited_cast,
    COALESCE(mg.genres, 'No genres') AS genres,
    COALESCE(mia.info_details, 'No additional info') AS additional_info,
    ROW_NUMBER() OVER (ORDER BY mh.production_year DESC, mh.title) AS ranking
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_summary cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    movie_genre mg ON mh.movie_id = mg.movie_id
LEFT JOIN 
    movie_info_agg mia ON mh.movie_id = mia.movie_id
WHERE 
    mh.depth < 3
ORDER BY 
    mh.production_year DESC, 
    mh.title;
