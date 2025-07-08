WITH RECURSIVE movie_cte AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'Unknown') AS keyword,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.movie_id = c.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
    HAVING 
        COUNT(c.person_id) > 5
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'Unknown') AS keyword,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.movie_id = c.movie_id
    WHERE 
        m.production_year = (SELECT MAX(production_year) FROM aka_title WHERE production_year < (SELECT MAX(production_year) FROM aka_title))
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
)
SELECT 
    m.title,
    m.production_year,
    m.keyword,
    m.cast_count,
    RANK() OVER (PARTITION BY m.keyword ORDER BY m.cast_count DESC) AS keyword_rank,
    CASE 
        WHEN m.cast_count > 20 THEN 'Highly Casted'
        WHEN m.cast_count BETWEEN 10 AND 20 THEN 'Moderately Casted'
        ELSE 'Less Casted'
    END AS cast_category
FROM 
    movie_cte m
LEFT JOIN 
    aka_name an ON m.cast_count = an.id
LEFT JOIN 
    person_info pi ON an.person_id = pi.person_id 
WHERE 
    (pi.info_type_id IS NULL OR pi.info_type_id = 1) 
    AND (m.keyword IS NOT NULL OR m.keyword != '')
ORDER BY 
    m.production_year DESC,
    m.cast_count DESC;


