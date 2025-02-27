WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL 
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
MovieTags AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
CompleteMovieInfo AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        COALESCE(mti.info, 'No additional info') AS additional_info,
        mt.keywords,
        ROW_NUMBER() OVER(PARTITION BY mh.production_year ORDER BY mh.level DESC) AS ranking
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        movie_info mti ON mh.movie_id = mti.movie_id
    LEFT JOIN 
        MovieTags mt ON mh.movie_id = mt.movie_id 
),
FilteredMovieList AS (
    SELECT 
        cmi.title,
        cmi.production_year,
        cmi.keywords
    FROM 
        CompleteMovieInfo cmi
    WHERE 
        cmi.ranking <= 5
        AND cmi.keywords IS NOT NULL
        AND cmi.production_year >= 1990 
)
SELECT 
    fml.title,
    fml.production_year,
    CASE 
        WHEN fml.keywords ILIKE '%comedy%' THEN 'Comedy'
        WHEN fml.keywords ILIKE '%drama%' THEN 'Drama'
        ELSE 'Other'
    END AS genre,
    COUNT(*) OVER(PARTITION BY fml.production_year) AS movie_count,
    COALESCE(NULLIF(STRING_AGG(DISTINCT a.name, ', '), ''), 'No actors listed') AS actors
FROM 
    FilteredMovieList fml
LEFT OUTER JOIN 
    cast_info ci ON fml.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
GROUP BY 
    fml.title, fml.production_year, fml.keywords
ORDER BY 
    fml.production_year DESC, genre;
