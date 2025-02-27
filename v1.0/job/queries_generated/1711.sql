WITH MovieActorInfo AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_order,
        COUNT(c.id) OVER (PARTITION BY t.id) AS total_cast
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(actor_name) AS actor_count
    FROM 
        MovieActorInfo
    GROUP BY 
        movie_title, production_year
    HAVING 
        COUNT(actor_name) > 3
)
SELECT 
    t.movie_title,
    t.production_year,
    m.name AS company_name,
    CASE 
        WHEN m.country_code IS NULL THEN 'Unknown'
        ELSE m.country_code
    END AS country_code,
    COALESCE(k.keyword, 'No Keywords') AS keyword_info
FROM 
    TopMovies t
LEFT JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM title WHERE title = t.movie_title AND production_year = t.production_year LIMIT 1)
LEFT JOIN 
    company_name m ON mc.company_id = m.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM title WHERE title = t.movie_title AND production_year = t.production_year LIMIT 1)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC,
    t.actor_count DESC;
