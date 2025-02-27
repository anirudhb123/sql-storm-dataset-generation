WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.level
),
TopMovies AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.level,
        fm.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY fm.level ORDER BY fm.keyword_count DESC) AS rn
    FROM 
        FilteredMovies fm
)

SELECT 
    tm.title,
    tm.production_year,
    tm.level,
    COALESCE(aka.name, 'Unknown') AS actor_name,
    COALESCE(c.role_id, 0) AS role_id,
    t.kind_id,
    CASE 
        WHEN t.production_year = 2020 THEN 'Recent Production'
        ELSE 'Older Production'
    END AS production_status,
    NULLIF(ci.note, '') AS cast_note
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name aka ON c.person_id = aka.person_id
JOIN 
    title t ON tm.movie_id = t.id
WHERE 
    tm.rn <= 10 
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
ORDER BY 
    tm.level, tm.keyword_count DESC;
