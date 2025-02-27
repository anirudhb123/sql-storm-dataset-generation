WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        h.movie_id AS parent_movie_id,
        h.level + 1
    FROM 
        aka_title e
    INNER JOIN 
        MovieHierarchy h ON e.episode_of_id = h.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.level,
        COUNT(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 END) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.level
    HAVING 
        COUNT(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 END) > 5
),
FilteredMovies AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.level,
        tm.cast_count,
        tm.actor_names,
        COALESCE(mi.info, 'No additional info') AS movie_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'IMDB Rating')
    WHERE 
        tm.level <= 2
)

SELECT 
    fm.movie_id,
    fm.title,
    fm.level,
    fm.cast_count,
    COALESCE(fm.actor_names, 'No actors listed') AS actor_names,
    fm.movie_info
FROM 
    FilteredMovies fm
ORDER BY 
    fm.level ASC, fm.cast_count DESC;

