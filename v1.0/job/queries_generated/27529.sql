WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
top_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        keywords
    FROM 
        ranked_movies
    WHERE 
        year_rank <= 5
),
performers AS (
    SELECT 
        p.id AS person_id,
        ak.name AS actor_name,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        p.id, ak.name
)
SELECT 
    tm.movie_title, 
    tm.production_year, 
    tm.keywords, 
    p.actor_name, 
    p.roles
FROM 
    top_movies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    performers p ON ak.person_id = p.person_id
ORDER BY 
    tm.production_year DESC, 
    tm.movie_title;
