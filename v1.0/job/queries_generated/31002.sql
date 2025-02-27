WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
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
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        AVG(CASE WHEN m.production_year < 2000 THEN 1 ELSE NULL END) AS classic_movie_ratio,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword kw ON m.id = kw.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
MovieSummary AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        md.cast_count,
        md.actors,
        md.classic_movie_ratio,
        md.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY md.cast_count DESC) AS rank
    FROM 
        MovieHierarchy mh
    JOIN 
        MovieDetails md ON mh.movie_id = md.movie_id
    WHERE 
        md.cast_count > 0
)
SELECT 
    ms.title,
    ms.production_year,
    ms.cast_count,
    COALESCE(ms.actors, 'No actors') AS actors,
    ms.classic_movie_ratio,
    ms.keyword_count,
    CASE 
        WHEN ms.rank <= 5 THEN 'Top 5'
        ELSE 'Others' 
    END AS rank_category
FROM 
    MovieSummary ms
WHERE 
    ms.production_year BETWEEN 1990 AND 2020
ORDER BY 
    ms.production_year DESC, 
    ms.cast_count DESC;
