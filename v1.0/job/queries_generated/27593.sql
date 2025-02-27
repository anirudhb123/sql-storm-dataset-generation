WITH Ranked_Actors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(ci.movie_id) DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
),
Top_Actors AS (
    SELECT 
        actor_id, actor_name
    FROM 
        Ranked_Actors
    WHERE 
        rank <= 10
),
Movie_Details AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        a.actor_name,
        GROUP_CONCAT(DISTINCT mtk.keyword ORDER BY mtk.keyword) AS keywords
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        Top_Actors a ON ci.person_id = a.actor_id
    LEFT JOIN 
        movie_keyword mtk ON mt.id = mtk.movie_id
    GROUP BY 
        mt.title, mt.production_year, a.actor_name
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.keywords
FROM 
    Movie_Details md
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, md.actor_name ASC;
