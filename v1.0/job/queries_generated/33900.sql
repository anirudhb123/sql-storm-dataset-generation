WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assuming kind_id 1 corresponds to movies

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        Title mt ON ml.movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
), MovieGenres AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(DISTINCT g.keyword, ', ') AS genres
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword g ON mk.keyword_id = g.id
    GROUP BY 
        mt.id
), MovieDetails AS (
    SELECT 
        mk.*,
        COALESCE(mh.level, -1) AS hierarchy_level,
        COALESCE(mg.genres, 'Unknown') AS genres,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC, mk.title ASC) AS rn
    FROM 
        aka_title mk
    LEFT JOIN 
        MovieHierarchy mh ON mk.id = mh.movie_id
    LEFT JOIN 
        MovieGenres mg ON mk.id = mg.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.genres,
    md.hierarchy_level,
    COUNT(ci.id) AS total_cast,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_notes,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE NULL END) AS avg_order_in_cast
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
WHERE 
    md.hierarchy_level <= 2  -- Consider movies with hierarchy level up to 2
GROUP BY 
    md.title, md.production_year, md.genres, md.hierarchy_level
ORDER BY 
    md.production_year DESC, total_cast DESC
LIMIT 100;
