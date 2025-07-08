
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
movies_with_awards AS (
    SELECT 
        r.movie_id,
        r.movie_title,
        r.production_year,
        r.keywords,
        r.cast_count,
        CASE 
            WHEN a.movie_id IS NOT NULL THEN 'Awarded' 
            ELSE 'Not Awarded' 
        END AS award_status
    FROM 
        ranked_movies r
    LEFT JOIN 
        movie_info mi ON r.movie_id = mi.movie_id 
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        (SELECT DISTINCT movie_id FROM movie_info WHERE info LIKE '%award%') a ON r.movie_id = a.movie_id
)
SELECT 
    m.movie_title, 
    m.production_year, 
    m.cast_count,
    m.keywords,
    m.award_status
FROM 
    movies_with_awards m
ORDER BY 
    m.production_year DESC, 
    m.cast_count DESC
LIMIT 50;
