WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(SUM(CASE WHEN cc.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count,
        NULL AS parent_movie_id
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    LEFT JOIN 
        title pt ON ml.linked_movie_id = pt.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id
    UNION ALL
    SELECT 
        pt.id AS movie_id,
        pt.title,
        pt.production_year,
        COALESCE(SUM(CASE WHEN cc.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count,
        mh.movie_id AS parent_movie_id
    FROM 
        title pt
    JOIN 
        movie_link ml ON pt.id = ml.linked_movie_id 
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
    LEFT JOIN 
        complete_cast cc ON pt.id = cc.movie_id
    GROUP BY 
        pt.id, mh.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.cast_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.cast_count DESC) AS year_rank
    FROM 
        MovieHierarchy mh
    WHERE 
        mh.cast_count > 0
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    COALESCE(aka.name, 'Unknown') AS main_actor,
    COALESCE(CAST(ki.keyword AS text), 'No Keyword') AS movie_keyword
FROM 
    FilteredMovies fm
LEFT JOIN 
    complete_cast cc ON fm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.id = ci.id
LEFT JOIN 
    aka_name aka ON ci.person_id = aka.person_id
LEFT JOIN 
    movie_keyword mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    fm.year_rank <= 5 
    AND (fm.production_year IS NOT NULL OR fm.production_year <> 0)
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
