WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        NULL::integer AS parent_id,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mc.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.movie_id,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link mc ON mh.movie_id = mc.movie_id
    JOIN 
        aka_title mt ON mc.linked_movie_id = mt.id
)

SELECT 
    mh.movie_id,
    mh.title,
    COALESCE((SELECT COUNT(DISTINCT c.person_id) 
               FROM cast_info c 
               WHERE c.movie_id = mh.movie_id 
               AND c.note IS NOT NULL), 0) AS actor_count,
    mh.depth,
    string_agg(a.name, ', ') AS actors,
    CASE 
        WHEN mh.depth = 0 THEN 'Original Movie' 
        ELSE 'Related Movie' 
    END AS movie_type
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.depth 
ORDER BY 
    mh.production_year DESC NULLS LAST, 
    actor_count DESC, 
    mh.depth ASC;

-- Below is the diagnostics query for performance comparing all related filter cases
WITH Benchmark AS (
    SELECT 
        t.id AS title_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        SUM(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS has_movie_info
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.id
)

SELECT 
    title_id,
    total_cast,
    keyword_count,
    has_movie_info,
    CASE 
        WHEN has_movie_info = 0 AND total_cast > 10 THEN 'Under-Infoed High Cast'
        WHEN has_movie_info = 1 AND total_cast < 5 THEN 'Well-Informed Low Cast'
        ELSE 'Average Info'
    END AS info_group
FROM 
    Benchmark
WHERE 
    (total_cast > 0 AND has_movie_info IS NOT NULL)
    OR title_id IN (SELECT title_id FROM Benchmark WHERE keyword_count > 5)
ORDER BY 
    total_cast DESC, has_movie_info DESC;

-- This is a combined query for overall insights and relationships between titles and their associated metadata
WITH TitleInsights AS (
    SELECT 
        t.id AS title_id,
        t.title,
        COUNT(DISTINCT c.person_id) AS num_cast,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        CASE 
            WHEN MIN(m.production_year) < 2000 THEN 'Classic'
            WHEN MIN(m.production_year) >= 2000 THEN 'Modern'
            ELSE 'Unknown'
        END AS era
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        aka_title m ON t.id = m.id
    GROUP BY 
        t.id, t.title
)

SELECT 
    title_id,
    title,
    num_cast,
    keywords,
    era,
    CASE 
        WHEN num_cast > 20 THEN 'Blockbuster'
        WHEN era = 'Classic' THEN 'Timeless'
        ELSE 'Indie'
    END AS classification
FROM 
    TitleInsights
WHERE 
    era IN ('Classic', 'Modern')
ORDER BY 
    num_cast DESC, title;
