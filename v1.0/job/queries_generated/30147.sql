WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000  -- Focus on movies from the year 2000 onwards

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link AS ml
    JOIN 
        title AS m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
),

MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS has_role
    FROM 
        MovieHierarchy AS mh
    LEFT JOIN 
        cast_info AS ci ON mh.movie_id = ci.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),

KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword AS mk
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    keyword_count.keyword_count,
    CASE 
        WHEN md.has_role > 0.5 THEN 'Mostly Cast' 
        ELSE 'Less Cast' 
    END AS cast_analysis,
    COALESCE(md.cast_count, 0) + COALESCE(keyword_count.keyword_count, 0) AS total_metric
FROM 
    MovieDetails AS md
LEFT JOIN 
    KeywordCount AS keyword_count ON md.movie_id = keyword_count.movie_id
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    total_metric DESC, 
    md.production_year DESC
LIMIT 50;
