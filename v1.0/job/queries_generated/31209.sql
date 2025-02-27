WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.episode_of_id IS NULL  -- Start from top-level movies (not episodes)
    
    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM 
        aka_title AS e
    INNER JOIN 
        movie_hierarchy AS mh ON e.episode_of_id = mh.movie_id  -- Join with episodes
),
ranked_cast AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS rank
    FROM 
        cast_info AS c
    JOIN 
        role_type AS r ON c.role_id = r.id
),
filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        movie_hierarchy AS mh
    LEFT JOIN 
        ranked_cast AS rc ON mh.movie_id = rc.movie_id
    LEFT JOIN 
        aka_name AS ak ON rc.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword AS mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS kc ON mk.keyword_id = kc.id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    COALESCE(fm.actors, 'No actors') AS actors,
    fm.keyword_count,
    CASE 
        WHEN fm.production_year >= 2000 THEN 'Modern'
        WHEN fm.production_year BETWEEN 1990 AND 1999 THEN '90s Classic'
        ELSE 'Older'
    END AS era
FROM 
    filtered_movies AS fm
WHERE 
    fm.keyword_count > 5  -- Filtering only movies with more than 5 keywords
ORDER BY 
    fm.production_year DESC, fm.title;
