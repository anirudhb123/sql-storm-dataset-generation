
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        NULL AS parent_id,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL  
    
    UNION ALL
    
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.episode_of_id AS parent_id,
        mh.level + 1 AS level
    FROM 
        aka_title t
    JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.parent_id,
        mh.level,
        COALESCE(ARRAY_AGG(DISTINCT kw.keyword), '{}') AS keywords,
        COALESCE(COUNT(DISTINCT c.person_id), 0) AS cast_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        cast_info c ON mh.movie_id = c.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.parent_id, mh.level
),
RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.parent_id,
        md.level,
        md.keywords,
        md.cast_count,
        ROW_NUMBER() OVER (PARTITION BY md.level ORDER BY md.production_year DESC, md.title) AS rank
    FROM 
        MovieDetails md
)
SELECT 
    r.title,
    r.production_year,
    r.keywords,
    r.cast_count,
    r.level,
    CASE 
        WHEN r.cast_count < 5 THEN 'Low'
        WHEN r.cast_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'High'
    END AS cast_size_category
FROM 
    RankedMovies r
WHERE 
    r.rank <= 10  
ORDER BY 
    r.level ASC, r.cast_count DESC;
