WITH RECURSIVE RecursiveCast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ak.person_id,
        1 AS depth
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ak.person_id,
        r.depth + 1
    FROM 
        cast_info ci
    JOIN 
        RecursiveCast r ON ci.movie_id = r.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        r.depth < 5 AND ak.name IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title
)
SELECT 
    m.title,
    COUNT(DISTINCT rc.actor_name) AS actor_count,
    COALESCE(m.keywords, 'No keywords') AS keywords,
    AVG(role_ratio) AS average_role_ratio
FROM 
    MoviesWithKeywords m
LEFT JOIN 
    RecursiveCast rc ON m.movie_id = rc.movie_id
LEFT JOIN (
    SELECT 
        mi.movie_id,
        COUNT(*) AS role_count,
        COUNT(DISTINCT ci.person_id) * 1.0 / NULLIF(COUNT(mi.id), 0) AS role_ratio
    FROM 
        movie_info mi
    LEFT JOIN 
        cast_info ci ON mi.movie_id = ci.movie_id
    GROUP BY 
        mi.movie_id
) AS roles ON m.movie_id = roles.movie_id
GROUP BY 
    m.movie_id, m.title
HAVING 
    AVG(role_ratio) > 0.5 AND COUNT(DISTINCT rc.actor_name) > 2
ORDER BY 
    movie_count DESC, m.title;
