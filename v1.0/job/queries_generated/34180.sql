WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.depth + 1,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.depth,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rank
    FROM 
        MovieHierarchy mh
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.depth,
        (SELECT COUNT(*) FROM cast_info c WHERE c.movie_id = rm.movie_id) AS num_cast,
        COALESCE((SELECT COUNT(*) FROM keyword k JOIN movie_keyword mk ON k.id = mk.keyword_id WHERE mk.movie_id = rm.movie_id), 0) AS num_keywords
    FROM 
        RankedMovies rm
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.depth,
    md.num_cast,
    md.num_keywords,
    CASE 
        WHEN md.num_cast > 10 THEN 'Highly Casted'
        WHEN md.num_cast BETWEEN 5 AND 10 THEN 'Moderately Casted'
        ELSE 'Less Casted'
    END AS cast_category,
    STRING_AGG(c.name, ', ') AS cast_names
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON ci.movie_id = md.movie_id
LEFT JOIN 
    aka_name c ON ci.person_id = c.person_id
WHERE 
    md.production_year >= 2000
GROUP BY 
    md.movie_id, md.title, md.production_year, md.depth, md.num_cast, md.num_keywords
ORDER BY 
    md.production_year DESC, md.title;
