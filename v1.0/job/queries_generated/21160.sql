WITH RECURSIVE movie_hierarchy AS (
    -- CTE to generate a hierarchy of movies based on links
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        1 AS level
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related')
    
    UNION ALL
    
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.linked_movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related')
),
cast_and_title AS (
    -- CTE for aggregating cast and title info
    SELECT 
        ct.movie_id,
        t.title,
        COUNT(DISTINCT c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        MAX(t.production_year) AS max_year
    FROM 
        cast_info c
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        ct.movie_id, t.title
),
titles_with_keywords AS (
    -- CTE to gather titles and their corresponding keywords
    SELECT 
        t.id AS title_id,
        t.title,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title
)
SELECT 
    t.id AS title_id,
    t.title,
    COALESCE(cast_info.cast_count, 0) AS cast_count,
    COALESCE(cast_info.actors, 'No cast available') AS actors,
    t.production_year,
    COALESCE(k.keywords, '{}'::text[]) AS keywords,
    movie_hierarchy.linked_movie_id,
    CASE 
        WHEN t.production_year IS NULL THEN 'Unknown Year'
        WHEN t.production_year < 2000 THEN 'Classic'
        WHEN t.production_year < 2010 THEN 'Modern Classic'
        ELSE 'Recent Release'
    END AS release_category
FROM 
    title t
LEFT JOIN 
    cast_and_title cast_info ON t.id = cast_info.movie_id
LEFT JOIN 
    titles_with_keywords k ON t.id = k.title_id
LEFT JOIN 
    movie_hierarchy ON t.id = movie_hierarchy.movie_id
WHERE 
    -- Filtering to include only titles related to a specific keyword or with cast info
    (k.keywords && ARRAY['Drama', 'Action'] OR cast_info.cast_count > 0)
    AND (t.production_year IS NOT NULL OR movie_hierarchy.linked_movie_id IS NOT NULL)
ORDER BY 
    t.production_year DESC, 
    cast_info.cast_count DESC
LIMIT 100;
