WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1 -- Assuming '1' is a valid kind_id for movies
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastStats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_roles,
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_role_assignment
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalStats AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cs.total_cast, 0) AS total_cast,
        COALESCE(cs.cast_with_roles, 0) AS cast_with_roles,
        COALESCE(cs.avg_role_assignment, 0) AS avg_role_assignment,
        COALESCE(ks.keywords, 'None') AS keywords,
        RANK() OVER (ORDER BY mh.production_year DESC) AS year_rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastStats cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        KeywordStats ks ON mh.movie_id = ks.movie_id
)
SELECT 
    fs.title,
    fs.production_year,
    fs.total_cast,
    fs.cast_with_roles,
    fs.avg_role_assignment,
    fs.keywords,
    CASE 
        WHEN fs.year_rank <= 10 THEN 'Top 10 Recent Movies'
        WHEN fs.production_year IS NULL THEN 'Unknown Year'
        ELSE 'Other'
    END AS ranking_category
FROM 
    FinalStats fs
WHERE 
    fs.production_year >= 2000  -- Filtering for movies from the year 2000 and onward
ORDER BY 
    fs.production_year DESC, fs.title;
