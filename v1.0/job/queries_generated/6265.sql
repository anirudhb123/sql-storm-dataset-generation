WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year AS release_year,
        c.name AS company_name,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT a.name) AS actors,
        COUNT(DISTINCT a.id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year, c.name
),
filtered_movies AS (
    SELECT 
        *,
        CASE 
            WHEN actor_count > 3 THEN 'Ensemble'
            WHEN actor_count = 3 THEN 'Trio'
            ELSE 'Duet or Solo'
        END AS cast_size
    FROM 
        movie_details
)
SELECT 
    movie_title,
    release_year,
    company_name,
    keywords,
    actors,
    cast_size
FROM 
    filtered_movies
WHERE 
    release_year >= 2000
ORDER BY 
    release_year DESC, actor_count DESC;
