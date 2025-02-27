WITH RECURSIVE movie_path AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        1 AS depth
    FROM 
        aka_title t
    JOIN 
        movie_link ml ON t.id = ml.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT 
        m.id,
        t.title,
        mp.depth + 1
    FROM 
        movie_path mp
    JOIN 
        movie_link ml ON mp.movie_id = ml.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        aka_title t ON m.id = t.movie_id
    WHERE 
        mp.depth < 5
),
cast_role_counts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        MAX(r.role) AS lead_role
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mp.title AS Movie_Title,
    mp.depth AS Depth,
    COALESCE(c.cast_count, 0) AS Cast_Count,
    COALESCE(c.lead_role, 'N/A') AS Lead_Role,
    COALESCE(mk.keywords, 'None') AS Keywords
FROM 
    movie_path mp
LEFT JOIN 
    cast_role_counts c ON mp.movie_id = c.movie_id
LEFT JOIN 
    movie_keywords mk ON mp.movie_id = mk.movie_id
WHERE 
    mp.depth BETWEEN 1 AND 5
ORDER BY 
    mp.depth, mp.title;
