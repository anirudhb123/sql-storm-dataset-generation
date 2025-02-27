WITH movie_cast AS (
    SELECT 
        a.title AS movie_title,
        p.name AS actor_name,
        c.nr_order AS cast_order,
        k.keyword AS movie_keyword,
        m.production_year
    FROM 
        aka_title AS a
    JOIN 
        cast_info AS c ON a.id = c.movie_id
    JOIN 
        aka_name AS p ON c.person_id = p.person_id
    LEFT JOIN 
        movie_keyword AS mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        title AS m ON a.id = m.id
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND m.production_year >= 2000
),
actor_summary AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        MIN(production_year) AS first_appearance,
        MAX(production_year) AS last_appearance
    FROM 
        movie_cast
    GROUP BY 
        actor_name
),
keyword_summary AS (
    SELECT 
        movie_keyword,
        COUNT(DISTINCT actor_name) AS actor_count
    FROM 
        movie_cast
    WHERE 
        movie_keyword IS NOT NULL
    GROUP BY 
        movie_keyword
)
SELECT 
    a.actor_name,
    a.movie_count,
    a.first_appearance,
    a.last_appearance,
    k.movie_keyword,
    k.actor_count
FROM 
    actor_summary AS a
LEFT JOIN 
    keyword_summary AS k ON a.keywords LIKE '%' || k.movie_keyword || '%'
ORDER BY 
    a.movie_count DESC, 
    a.actor_name;
