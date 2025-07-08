
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'genre')
    GROUP BY 
        t.id, t.title, t.production_year
),
recent_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year
    FROM 
        ranked_movies
    WHERE 
        production_year >= 2010
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    kp.keyword AS popular_keyword,
    COUNT(mc.company_id) AS company_count
FROM 
    recent_movies rm
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kp ON mk.keyword_id = kp.id
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, kp.keyword
ORDER BY 
    rm.production_year DESC, company_count DESC
LIMIT 100;
