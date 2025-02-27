WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
MovieRankings AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COUNT(cc.id) AS cast_count,
        AVG(PERCENT_RANK() OVER (PARTITION BY mt.production_year ORDER BY cc.nr_order)) AS average_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info cc ON mt.id = cc.movie_id
    GROUP BY 
        mt.id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mri.cast_count,
        CASE 
            WHEN mri.cast_count IS NULL THEN 'No Cast'
            ELSE 'Has Cast'
        END AS cast_status
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieRankings mri ON mh.movie_id = mri.movie_id
    WHERE 
        mh.depth = 1 AND
        (mh.production_year IS NOT NULL AND mh.production_year > 1990)
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.cast_status,
    COALESCE(st.keyword, 'No Keywords') AS associated_keyword
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword st ON mk.keyword_id = st.id
WHERE 
    md.cast_status = 'Has Cast'
ORDER BY 
    md.production_year DESC, md.cast_count DESC
LIMIT 50;
