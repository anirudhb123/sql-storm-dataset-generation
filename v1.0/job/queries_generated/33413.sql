WITH RECURSIVE cte_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        c.depth + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON ml.movie_id = m.id
    INNER JOIN 
        cte_movies c ON c.movie_id = ml.linked_movie_id
    WHERE 
        c.depth < 3
), 
movie_with_keywords AS (
    SELECT 
        m.movie_id,
        m.title,
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        cte_movies m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        m.movie_id, m.title
), 
cast_info_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS unique_cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    GROUP BY 
        c.movie_id
)
SELECT 
    mwk.title,
    mwk.production_year,
    mwk.keywords,
    c.unique_cast_count,
    c.cast_names,
    CASE 
        WHEN c.unique_cast_count IS NULL THEN 'No Cast Information' 
        ELSE c.unique_cast_count::TEXT 
    END AS cast_info_status
FROM 
    movie_with_keywords mwk
LEFT JOIN 
    cast_info_summary c ON mwk.movie_id = c.movie_id
WHERE 
    mwk.production_year = (SELECT MAX(production_year) FROM aka_title)
ORDER BY 
    mwk.title;
