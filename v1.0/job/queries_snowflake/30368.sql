
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        mh.level + 1 AS level
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
role_stats AS (
    SELECT
        ci.role_id,
        COUNT(*) AS actor_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_present_rate
    FROM 
        cast_info ci
    GROUP BY 
        ci.role_id
),
movies_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.level,
    COALESCE(mkw.keywords, 'No keywords') AS keywords,
    COALESCE(rs.actor_count, 0) AS actor_count,
    COALESCE(rs.note_present_rate, 0) AS note_present_rate,
    CASE 
        WHEN COALESCE(rs.actor_count, 0) >= 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity_category
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movies_with_keywords mkw ON mh.movie_id = mkw.movie_id
LEFT JOIN 
    role_stats rs ON rs.role_id IN (
        SELECT DISTINCT ci.role_id 
        FROM cast_info ci 
        WHERE ci.movie_id = mh.movie_id
    )
ORDER BY 
    mh.level, mh.title;
