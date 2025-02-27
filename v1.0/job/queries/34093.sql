
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL AS parent_title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.title AS parent_title,
        mh.level + 1
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),
AggregatedCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.parent_title,
        ac.total_cast,
        ac.cast_names,
        ROW_NUMBER() OVER (PARTITION BY mh.parent_title ORDER BY mh.production_year) AS rn
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        AggregatedCast ac ON mh.movie_id = ac.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.parent_title,
    COALESCE(md.total_cast, 0) AS total_cast,
    md.cast_names,
    CASE 
        WHEN md.parent_title IS NOT NULL THEN 'Episode'
        ELSE 'Movie'
    END AS movie_type,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM 
    MovieDetails md
LEFT JOIN 
    movie_companies mc ON md.movie_id = mc.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.parent_title, md.total_cast, md.cast_names
HAVING 
    md.production_year >= 2000 AND 
    (md.total_cast IS NULL OR md.total_cast > 5)
ORDER BY 
    md.production_year DESC, md.movie_id;
