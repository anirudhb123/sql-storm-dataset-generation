WITH movie_ratings AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(AVG(r.rating), 0) AS avg_rating,
        COUNT(DISTINCT r.user_id) AS user_count
    FROM 
        title m
    LEFT JOIN 
        ratings r ON m.id = r.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id
),

actors_with_roles AS (
    SELECT 
        a.person_id,
        a.name,
        STRING_AGG(DISTINCT r.role, ', ') AS roles,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),

banned_keywords AS (
    SELECT 
        'offensive' AS keyword
    UNION ALL
    SELECT 
        'adult'
),

filtered_movies AS (
    SELECT 
        m.id,
        m.title,
        m.production_year,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        NOT EXISTS (SELECT 1 FROM banned_keywords b WHERE b.keyword = ANY(ARRAY_AGG(k.keyword)))
)

SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.keywords,
    COALESCE(mr.avg_rating, 0) AS avg_rating,
    COALESCE(mr.user_count, 0) AS user_count,
    awr.roles,
    awr.movie_count
FROM 
    filtered_movies f
LEFT JOIN 
    movie_ratings mr ON f.movie_id = mr.movie_id
LEFT JOIN 
    actors_with_roles awr ON f.movie_id IN (
        SELECT 
            c.movie_id 
        FROM 
            cast_info c 
        WHERE 
            c.person_id = awr.person_id
    )
WHERE 
    (f.production_year BETWEEN 2000 AND 2023 OR f.keywords IS NULL)
ORDER BY 
    avg_rating DESC, f.production_year DESC
LIMIT 100;
