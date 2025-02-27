WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        COUNT(cast.person_id) AS cast_count,
        RANK() OVER (PARTITION BY mh.depth ORDER BY COUNT(cast.person_id) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info cast ON mh.movie_id = cast.movie_id
    GROUP BY 
        mh.movie_id, mh.movie_title, mh.depth
),

NotableKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

FinalMovieReport AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.cast_count,
        nk.keywords,
        COALESCE(m.production_year, 'N/A') AS production_year
    FROM 
        RankedMovies rm
    LEFT JOIN 
        aka_title m ON rm.movie_id = m.id
    LEFT JOIN 
        NotableKeywords nk ON rm.movie_id = nk.movie_id
)

SELECT 
    movie_title,
    cast_count,
    keywords,
    production_year
FROM 
    FinalMovieReport
WHERE 
    rank <= 5
ORDER BY 
    production_year DESC NULLS LAST;
