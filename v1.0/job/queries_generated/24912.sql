WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastStats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        SUM(CASE WHEN ci.note IS NOT NULL AND ci.note != '' THEN 1 ELSE 0 END) AS actors_with_notes,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS average_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ' ORDER BY k.keyword) AS keywords,
        COUNT(k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cs.total_actors, 0) AS total_actors,
    COALESCE(cs.actors_with_notes, 0) AS actors_with_notes,
    COALESCE(cs.average_order, 0) AS average_order,
    COALESCE(ks.keywords, 'No keywords') AS keywords,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN mh.production_year IS NULL THEN 'Unknown Year'
        WHEN mh.production_year < 2010 THEN 'Early'
        ELSE 'Recent'
    END AS production_category,
    CASE 
        WHEN mh.production_year IS NULL AND mh.title IS NULL THEN 'Several mysteries abound'
        ELSE 'Details available'
    END AS mystery_level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastStats cs ON mh.movie_id = cs.movie_id
LEFT JOIN 
    KeywordStats ks ON mh.movie_id = ks.movie_id
WHERE 
    (cs.total_actors IS NOT NULL AND cs.total_actors > 0)
    OR (ks.keyword_count IS NOT NULL AND ks.keyword_count > 0)
ORDER BY 
    mh.production_year DESC, 
    mh.title
LIMIT 100;

