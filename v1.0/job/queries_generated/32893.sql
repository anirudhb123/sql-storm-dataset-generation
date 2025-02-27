WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = 1  -- Assuming 1 represents movies
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        mk.title,
        mk.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title mk ON ml.linked_movie_id = mk.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

movie_cast_info AS (
    SELECT
        mc.movie_id,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        mc.movie_id
),

filtered_movies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mci.cast_count,
        mci.cast_names,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mci.cast_count DESC) AS rn
    FROM
        movie_hierarchy mh
    LEFT JOIN
        movie_cast_info mci ON mh.movie_id = mci.movie_id
    WHERE
        mh.production_year > 2000  -- Focusing on modern movies
)

SELECT
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    f.cast_names,
    COALESCE(mt.info, 'No additional info') AS additional_info,
    CASE 
        WHEN f.cast_count IS NULL THEN 'No cast'
        WHEN f.cast_count < 5 THEN 'Small Cast'
        ELSE 'Large Cast'
    END AS cast_size_category
FROM
    filtered_movies f
LEFT JOIN
    (SELECT 
         mi.movie_id, 
         JSON_AGG(mi.info) AS info 
     FROM 
         movie_info mi 
     GROUP BY 
         mi.movie_id) mt ON f.movie_id = mt.movie_id
WHERE
    f.rn <= 3  -- Only top 3 movies per year
ORDER BY
    f.production_year,
    f.cast_count DESC;
