WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1  -- Assuming kind_id = 1 is for movies

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.movie_id = mh.id
    JOIN 
        aka_title linked_m ON ml.linked_movie_id = linked_m.id
    JOIN 
        MovieHierarchy mh ON mh.id = ml.movie_id
    WHERE 
        linked_m.kind_id = 1
),
TitleInfo AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        COUNT(ci.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, mk.keyword
),
AverageProductionYear AS (
    SELECT 
        AVG(production_year) AS avg_year
    FROM 
        aka_title
)
SELECT 
    ti.title,
    ti.production_year,
    ti.keyword,
    ti.cast_count,
    (SELECT 
        COUNT(DISTINCT mc.company_id)
     FROM 
        movie_companies mc
     WHERE 
        mc.movie_id = ti.id) AS company_count,
    (SELECT 
        COUNT(DISTINCT ml.linked_movie_id)
     FROM 
        movie_link ml
     WHERE 
        ml.movie_id = ti.id) AS linked_count,
    CASE 
        WHEN ti.production_year < (SELECT avg_year FROM AverageProductionYear) THEN 'Before Average'
        ELSE 'After Average'
    END AS year_comparison,
    mh.level
FROM 
    TitleInfo ti
LEFT JOIN 
    MovieHierarchy mh ON ti.id = mh.id
ORDER BY 
    ti.production_year DESC,
    ti.title ASC
LIMIT 100;
