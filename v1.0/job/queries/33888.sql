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
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.depth < 3
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(cc.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(cc.id) DESC) AS rn
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info cc ON mh.movie_id = cc.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
FilteredMovies AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_count
    FROM 
        TopMovies tm
    WHERE 
        tm.rn <= 10
)
SELECT 
    f.title AS Movie_Title,
    f.production_year AS Production_Year,
    COALESCE(cn.name, 'Unknown') AS Company_Name,
    f.cast_count AS Cast_Count,
    it.info AS Additional_Info
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_companies mc ON f.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON f.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    f.cast_count > 0
ORDER BY 
    f.production_year DESC, f.cast_count DESC;

