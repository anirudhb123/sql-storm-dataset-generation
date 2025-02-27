WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY c.role_id ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
staff_info AS (
    SELECT 
        p.id AS person_id,
        p.name,
        p.gender,
        COUNT(ci.id) AS movie_count
    FROM 
        name p
    LEFT JOIN 
        cast_info ci ON p.id = ci.person_id
    GROUP BY 
        p.id, p.name, p.gender
),
popular_movies AS (
    SELECT 
        m.movie_id, 
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        complete_cast m
    JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    GROUP BY 
        m.movie_id
    HAVING 
        COUNT(DISTINCT ci.person_id) > 10
),
keyword_details AS (
    SELECT 
        k.keyword,
        COUNT(mk.movie_id) AS movie_keyword_count
    FROM 
        keyword k
    LEFT JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    WHERE 
        LENGTH(k.keyword) > 5
    GROUP BY 
        k.keyword
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    s.name AS actor_name,
    s.gender,
    s.movie_count,
    COALESCE(p.cast_count, 0) AS cast_count,
    k.keyword AS keyword_used,
    k.movie_keyword_count
FROM 
    ranked_movies r
JOIN 
    staff_info s ON s.person_id = (
        SELECT ci.person_id 
        FROM cast_info ci 
        WHERE ci.movie_id = r.movie_id 
        ORDER BY ci.nr_order 
        LIMIT 1
    )
LEFT JOIN 
    popular_movies p ON r.movie_id = p.movie_id
LEFT JOIN 
    keyword_details k ON r.movie_id IN (
        SELECT mk.movie_id
        FROM movie_keyword mk
        WHERE mk.keyword_id = (
            SELECT id FROM keyword WHERE keyword = 'drama'
        )
    )
WHERE 
    r.year_rank = 1 
    AND s.gender = 'F'
ORDER BY 
    r.production_year DESC, 
    s.movie_count DESC, 
    k.movie_keyword_count DESC;
