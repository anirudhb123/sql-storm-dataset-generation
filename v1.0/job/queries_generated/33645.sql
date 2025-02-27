WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY[mt.title] AS title_path,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.title_path || a.title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    WHERE 
        a.production_year >= 2000
),
MovieMetrics AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info c ON mh.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.level
),
TitleWithKeywords AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        kt.keyword
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    WHERE 
        kt.keyword IS NOT NULL
)
SELECT 
    mm.movie_id,
    mm.title,
    mm.production_year,
    mm.num_cast_members,
    mm.cast_names,
    COUNT(DISTINCT tk.keyword) AS num_keywords,
    MAX(mm.level) AS max_hierarchy_level
FROM 
    MovieMetrics mm
LEFT JOIN 
    TitleWithKeywords tk ON mm.movie_id = tk.movie_id
WHERE 
    mm.production_year BETWEEN 2000 AND 2023
GROUP BY 
    mm.movie_id, mm.title, mm.production_year, mm.num_cast_members, mm.cast_names
ORDER BY 
    num_cast_members DESC, production_year DESC;
