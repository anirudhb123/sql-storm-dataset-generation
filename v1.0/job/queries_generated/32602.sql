WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        m.production_year >= 2000
),
latest_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(cc.id) AS cast_count,
        COALESCE(SUM(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END), 0) AS named_roles
    FROM 
        movie_hierarchy a
    LEFT JOIN 
        cast_info cc ON a.movie_id = cc.movie_id
    LEFT JOIN 
        role_type r ON cc.role_id = r.id
    GROUP BY 
        a.title, a.production_year
),
top_movies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        named_roles,
        RANK() OVER (ORDER BY cast_count DESC, named_roles DESC) AS rank
    FROM 
        latest_movies
),
influential_movies AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        tm.named_roles
    FROM 
        top_movies tm
    WHERE 
        tm.rank <= 10
)
SELECT 
    im.title,
    im.production_year,
    im.cast_count,
    im.named_roles,
    CASE 
        WHEN im.named_roles > 5 THEN 'Highly Influential'
        WHEN im.named_roles BETWEEN 3 AND 5 THEN 'Moderately Influential'
        ELSE 'Less Influential'
    END AS influence_category
FROM 
    influential_movies im
LEFT JOIN 
    aka_title at ON at.title = im.title
WHERE 
    at.production_year BETWEEN 2000 AND 2023
ORDER BY 
    im.cast_count DESC, 
    im.named_roles DESC;
