WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1,
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
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rn
    FROM 
        MovieHierarchy mh
),
MovieDetails AS (
    SELECT 
        r.movie_id,
        r.title,
        COALESCE(NULLIF(r.production_year, 0), 'Unknown') AS production_year,
        r.level,
        c.name AS cast_name,
        string_agg(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        RankedMovies r
    LEFT JOIN 
        cast_info ci ON r.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON r.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        r.rn <= 5 
    GROUP BY 
        r.movie_id, r.title, r.production_year, r.level, c.name
)
SELECT 
    md.title,
    md.production_year,
    md.level,
    md.cast_name,
    CASE 
        WHEN md.level = 1 THEN 'Original Movie'
        ELSE 'Episode'
    END AS movie_type,
    CASE 
        WHEN md.keywords IS NULL THEN 'No Keywords Found'
        ELSE md.keywords
    END AS movie_keywords
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.level, md.title;
