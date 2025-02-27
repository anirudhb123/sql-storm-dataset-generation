WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_stats AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(c.id) AS total_movies,
        MAX(CASE WHEN m.production_year IS NOT NULL THEN m.production_year ELSE 0 END) AS last_movie_year
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        aka_title m ON c.movie_id = m.id
    WHERE 
        a.name IS NOT NULL AND CHAR_LENGTH(a.name) > 3
    GROUP BY 
        a.person_id, a.name
),
missing_info AS (
    SELECT 
        co.name AS company_name,
        mc.note, 
        COUNT(c.movie_id) AS num_movies
    FROM 
        company_name co
    LEFT JOIN 
        movie_companies mc ON co.id = mc.company_id
    LEFT JOIN 
        aka_title t ON mc.movie_id = t.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        co.name IS NOT NULL AND mc.note IS NOT NULL
    GROUP BY 
        co.name, mc.note
    HAVING 
        COUNT(c.movie_id) < 5
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    a.name AS actor_name,
    a.total_movies,
    a.last_movie_year,
    m.company_name,
    m.num_movies
FROM 
    ranked_movies r
FULL OUTER JOIN 
    actor_stats a ON r.rank < 6 AND a.total_movies > 2
LEFT JOIN 
    missing_info m ON r.movie_id IN (SELECT c.movie_id FROM cast_info c WHERE a.person_id = c.person_id)
WHERE 
    (r.production_year IS NULL OR r.production_year >= 2000)
    AND (a.last_movie_year IS NULL OR a.last_movie_year <= 2023)
ORDER BY 
    r.production_year DESC, 
    a.total_movies DESC, 
    m.num_movies ASC
LIMIT 100;
