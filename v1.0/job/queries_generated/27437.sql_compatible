
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title m 
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id 
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id 
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id 
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id 
    GROUP BY 
        m.id, m.title, m.production_year
),
filtered_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        actor_names,
        keywords,
        cast_count
    FROM 
        ranked_movies
    WHERE 
        production_year BETWEEN 2000 AND 2020 
        AND cast_count > 5
)
SELECT 
    fm.movie_id,
    fm.movie_title,
    fm.production_year,
    fm.actor_names,
    fm.keywords,
    fm.cast_count,
    ct.kind AS company_type
FROM 
    filtered_movies fm
JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
