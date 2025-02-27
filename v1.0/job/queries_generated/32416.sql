WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    INNER JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank
    FROM 
        MovieHierarchy mh
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(CAST(SUM(mk.keyword IS NOT NULL) AS INTEGER), 0) AS keyword_count,
        COALESCE(CAST(SUM(DISTINCT ci.person_id) AS INTEGER), 0) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = tm.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = tm.movie_id
    LEFT JOIN 
        aka_title ak ON ak.movie_id = tm.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.keyword_count,
    md.cast_count,
    CASE 
        WHEN md.cast_count IS NULL THEN 'No Cast Information'
        ELSE 'Has Cast Information'
    END AS cast_info_status,
    md.aka_names
FROM 
    MovieDetails md
WHERE 
    md.keyword_count > 0 OR md.cast_count > 0
ORDER BY 
    md.production_year DESC, 
    md.keyword_count DESC;
