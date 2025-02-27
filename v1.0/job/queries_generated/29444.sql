WITH movie_stats AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.person_id) AS cast_members,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),

movie_quality AS (
    SELECT 
        ms.title_id,
        ms.movie_title,
        ms.production_year,
        ms.cast_members,
     	CASE 
            WHEN ms.keyword_count > 5 THEN 'High'
            WHEN ms.keyword_count BETWEEN 3 AND 5 THEN 'Medium'
            ELSE 'Low'
        END AS quality_rating
    FROM 
        movie_stats ms
)

SELECT 
    mq.title_id,
    mq.movie_title,
    mq.production_year,
    mq.cast_members,
    mq.quality_rating,
    COUNT(DISTINCT c2.person_id) AS directors_count,
    COUNT(DISTINCT c3.person_id) AS producers_count
FROM 
    movie_quality mq
LEFT JOIN 
    cast_info c2 ON mq.title_id = c2.movie_id AND c2.role_id = (SELECT id FROM role_type WHERE role = 'Director')
LEFT JOIN 
    cast_info c3 ON mq.title_id = c3.movie_id AND c3.role_id = (SELECT id FROM role_type WHERE role = 'Producer')
GROUP BY 
    mq.title_id, mq.movie_title, mq.production_year, mq.cast_members, mq.quality_rating
ORDER BY 
    mq.production_year DESC, mq.quality_rating DESC;
