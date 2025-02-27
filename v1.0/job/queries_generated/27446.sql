WITH movie_performance AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role), ', ') AS cast_list,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id AND cc.movie_id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    mp.movie_title,
    mp.production_year,
    mp.total_cast,
    mp.cast_list,
    ARRAY_LENGTH(mp.keywords, 1) AS keyword_count
FROM 
    movie_performance mp
ORDER BY 
    mp.production_year DESC, 
    mp.total_cast DESC
LIMIT 10;
