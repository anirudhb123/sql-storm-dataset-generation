WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        GROUP_CONCAT(DISTINCT a.name) AS actor_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
), actor_stats AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        AVG(CASE WHEN t.production_year BETWEEN 2000 AND 2010 THEN 1 ELSE 0 END) AS avg_movies_2000s,
        AVG(CASE WHEN t.production_year > 2010 THEN 1 ELSE 0 END) AS avg_movies_2010s
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    JOIN 
        title t ON ci.movie_id = t.id
    GROUP BY 
        a.id, a.name
)
SELECT 
    md.movie_title,
    md.production_year,
    md.cast_count,
    md.actor_names,
    md.keywords,
    as.actor_id,
    as.actor_name,
    as.movies_count,
    as.avg_movies_2000s,
    as.avg_movies_2010s
FROM 
    movie_details md
JOIN 
    actor_stats as ON md.actor_names LIKE CONCAT('%', as.actor_name, '%')
ORDER BY 
    md.production_year DESC, md.cast_count DESC, as.movies_count DESC
LIMIT 50;
