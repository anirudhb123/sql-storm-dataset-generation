WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        ml.movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
), 
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY mh.movie_id) AS cast_count,
        AVG(m.production_year) OVER (PARTITION BY mh.movie_id) AS avg_year
    FROM 
        MovieHierarchy mh
    JOIN 
        complete_cast m ON mh.movie_id = m.movie_id
    JOIN 
        cast_info c ON m.subject_id = c.person_id
), 
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.cast_count,
        rm.avg_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count >= 5 AND rm.avg_year >= 2010
),
CoActors AS (
    SELECT 
        c1.movie_id,
        c1.person_id AS actor_id,
        STRING_AGG(DISTINCT name.name, ', ') AS co_actor_names
    FROM 
        cast_info c1
    JOIN 
        cast_info c2 ON c1.movie_id = c2.movie_id AND c1.person_id <> c2.person_id
    JOIN 
        name ON c2.person_id = name.id
    GROUP BY 
        c1.movie_id, c1.person_id
)
SELECT 
    fm.movie_id,
    fm.movie_title,
    fm.cast_count,
    fm.avg_year,
    ca.co_actor_names
FROM 
    FilteredMovies fm
LEFT JOIN 
    CoActors ca ON fm.movie_id = ca.movie_id
ORDER BY 
    fm.cast_count DESC, fm.avg_year DESC;
