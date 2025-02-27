
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000  
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        h.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy h ON m.episode_of_id = h.movie_id  
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank_within_year
    FROM 
        MovieHierarchy mh
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_within_year <= 5  
),
CastDetails AS (
    SELECT 
        f.movie_id,
        COUNT(ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        FilteredMovies f
    LEFT JOIN 
        cast_info ci ON f.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        f.movie_id
)
SELECT 
    fm.movie_id,
    fm.movie_title,
    fm.production_year,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(cd.cast_names, 'No Cast') AS cast_names,
    CASE 
        WHEN COALESCE(cd.total_cast, 0) = 0 THEN 'No Cast' 
        ELSE CAST(cd.total_cast AS VARCHAR) 
    END AS cast_info 
FROM 
    FilteredMovies fm
LEFT JOIN 
    CastDetails cd ON fm.movie_id = cd.movie_id
ORDER BY 
    fm.production_year DESC, 
    COALESCE(cd.total_cast, 0) DESC;
