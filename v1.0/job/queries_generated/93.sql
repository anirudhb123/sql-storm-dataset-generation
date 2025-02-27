WITH movie_cast AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name, 
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
), 
movie_keywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
production_info AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(m.title, 'Unknown Title') AS title,
        COALESCE(m.production_year, 0) AS production_year,
        COALESCE(k.keywords, 'None') AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_keywords k ON m.id = k.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, k.keywords
) 
SELECT 
    p.movie_id,
    p.title,
    p.production_year,
    p.keywords,
    COALESCE(m.actor_name, 'No Actors') AS leading_actor
FROM 
    production_info p
LEFT JOIN 
    movie_cast m ON p.movie_id = m.movie_id AND m.actor_rank = 1
WHERE 
    (p.production_year < 2000 OR p.keywords LIKE '%Drama%')
ORDER BY 
    p.production_year DESC, p.title;
