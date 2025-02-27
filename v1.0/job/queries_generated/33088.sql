WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON a.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rn
    FROM 
        MovieHierarchy mh
    WHERE 
        mh.title ILIKE '%adventure%'  -- Filter titles with 'adventure'
),
TopMovies AS (
    SELECT 
        f.movie_id,
        f.title,
        f.production_year
    FROM 
        FilteredMovies f
    WHERE 
        f.rn <= 5  -- Get top 5 movies per production year
),
CastInfoAndRoles AS (
    SELECT 
        c.movie_id,
        a.name,
        r.role
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        role_type r ON r.id = c.role_id
)
SELECT 
    tm.title,
    tm.production_year,
    STRING_AGG(DISTINCT cir.name || ' as ' || cir.role, ', ') AS cast,
    COALESCE(NULLIF(STRING_AGG(DISTINCT ci.info, ', '), ''), 'No additional info') AS additional_info
FROM 
    TopMovies tm
LEFT JOIN 
    CastInfoAndRoles cir ON cir.movie_id = tm.movie_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = tm.movie_id
LEFT JOIN 
    info_type it ON it.id = mi.info_type_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, tm.title;
