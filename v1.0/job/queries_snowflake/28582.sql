
WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aliases,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.title, a.production_year
),
top_movies AS (
    SELECT 
        title,
        production_year,
        actor_count,
        aliases,
        keywords,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    title,
    production_year,
    actor_count,
    aliases,
    keywords
FROM 
    top_movies
WHERE 
    rank <= 10
ORDER BY 
    actor_count DESC;
