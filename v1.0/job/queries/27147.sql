WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        a.surname_pcode,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON c.movie_id = m.id
    JOIN 
        aka_name a ON a.person_id = c.person_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword, a.name, a.surname_pcode
),
filtered_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        movie_keyword,
        actor_name,
        surname_pcode,
        total_cast,
        DENSE_RANK() OVER (PARTITION BY movie_keyword ORDER BY total_cast DESC) AS keyword_rank
    FROM 
        movie_details
)
SELECT 
    f.movie_id,
    f.movie_title,
    f.production_year,
    f.movie_keyword,
    f.actor_name,
    f.surname_pcode,
    f.total_cast
FROM 
    filtered_movies f
WHERE 
    f.keyword_rank <= 3
ORDER BY 
    f.movie_keyword, f.total_cast DESC;