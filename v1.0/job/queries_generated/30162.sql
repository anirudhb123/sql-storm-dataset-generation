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
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1 AS depth
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        depth
    FROM 
        MovieHierarchy
    WHERE 
        depth <= 3
),
MovieCast AS (
    SELECT 
        f.movie_id,
        f.title,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name) AS cast_names,
        COUNT(DISTINCT c.id) AS cast_count,
        MIN(c.nr_order) AS first_cast_order
    FROM 
        FilteredMovies f
    LEFT JOIN 
        cast_info c ON f.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        f.movie_id, f.title, f.production_year
)
SELECT 
    mc.movie_id,
    mc.title,
    mc.production_year,
    mc.cast_names,
    mc.cast_count,
    CASE 
        WHEN mc.cast_count IS NULL THEN 'No Cast'
        ELSE CONCAT(mc.cast_count, ' Cast Members')
    END AS cast_description,
    COALESCE(NULLIF(mc.first_cast_order, 0), -1) AS first_cast_order
FROM 
    MovieCast mc
JOIN 
    aka_title at ON mc.movie_id = at.id
LEFT JOIN 
    movie_info mi ON mc.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
WHERE 
    at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
ORDER BY 
    mc.production_year DESC, 
    mc.cast_count DESC 
LIMIT 50;
