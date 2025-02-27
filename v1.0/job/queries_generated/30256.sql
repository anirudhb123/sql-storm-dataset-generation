WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(COUNT(DISTINCT ci.person_id), 0) AS cast_count,
        MAX(ti.info) AS best_review
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_info mi ON mh.movie_id = mi.movie_id
    LEFT JOIN 
        info_type ti ON mi.info_type_id = ti.id AND ti.info = 'Review'
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.best_review,
        RANK() OVER (ORDER BY md.cast_count DESC, md.production_year ASC) AS rank
    FROM 
        MovieDetails md
)
SELECT 
    rm.rank,
    rm.title,
    rm.production_year,
    rm.cast_count,
    CASE 
        WHEN rm.best_review IS NULL THEN 'No reviews available'
        ELSE rm.best_review 
    END AS best_review
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.rank;
