WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        CAST(NULL AS text) AS parent_movie_title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL  -- Starting from top-level movies

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        p.title AS parent_movie_title,
        h.level + 1 AS level
    FROM 
        aka_title e
    JOIN 
        aka_title p ON e.episode_of_id = p.id
    JOIN 
        MovieHierarchy h ON p.id = h.movie_id
)

SELECT 
    mk.keyword,
    COUNT(DISTINCT mv.movie_id) AS movie_count,
    AVG(mv.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT mv.title, ', ') AS titles,
    COALESCE(MAX(sub.rating), 0) AS max_rating,
    SUM(CASE WHEN mv.production_year < 2000 THEN 1 ELSE 0 END) AS before_2000_count,
    ARRAY_AGG(DISTINCT cn.name) FILTER (WHERE cn.name IS NOT NULL) AS company_names
FROM 
    movie_keyword mk
JOIN 
    movie_info mi ON mi.movie_id = mk.movie_id
JOIN 
    MovieHierarchy mv ON mv.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mv.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN (
    SELECT 
        m.id AS movie_id,
        AVG(r.rating) AS rating
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON mi.movie_id = m.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    LEFT JOIN 
        unnest(string_to_array(mi.info, '/')) AS r(rating) ON r.rating IS NOT NULL
    GROUP BY 
        m.id
) sub ON sub.movie_id = mv.movie_id
WHERE 
    mk.keyword IS NOT NULL
GROUP BY 
    mk.keyword
ORDER BY 
    movie_count DESC, avg_production_year DESC;
