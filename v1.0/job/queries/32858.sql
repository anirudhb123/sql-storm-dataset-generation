WITH RECURSIVE MovieHierarchy AS (
    
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        0 AS depth
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        e.episode_of_id,
        mh.depth + 1 AS depth
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),
TopMovies AS (
    
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(*) AS episode_count
    FROM 
        MovieHierarchy mh
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    ORDER BY 
        episode_count DESC
    LIMIT 10
),
MovieDetails AS (
    
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.keywords,
    COALESCE(ak.name, 'Unknown') AS director_name,
    CASE 
        WHEN md.cast_count > 10 THEN 'Large Ensemble'
        WHEN md.cast_count BETWEEN 5 AND 10 THEN 'Medium Ensemble'
        ELSE 'Small Ensemble'
    END AS ensemble_type
FROM 
    MovieDetails md
LEFT JOIN 
    (SELECT 
         DISTINCT ci.movie_id,
         ak.name
     FROM 
         cast_info ci
     JOIN 
         AKA_name ak ON ci.person_id = ak.person_id
     WHERE 
         ci.role_id = (SELECT id FROM role_type WHERE role = 'director')
    ) AS ak ON md.movie_id = ak.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC,
    md.cast_count DESC;