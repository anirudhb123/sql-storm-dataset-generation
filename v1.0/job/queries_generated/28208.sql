WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.id AS cast_id,
        ak.name AS actor_name,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id AND ci.id = cc.subject_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, c.id, ak.name
),
ActorPerformance AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS movies_featured,
        SUM(keyword_count) AS total_keywords
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
)
SELECT 
    actor_name,
    movies_featured,
    total_keywords,
    RANK() OVER (ORDER BY movies_featured DESC, total_keywords DESC) AS ranking
FROM 
    ActorPerformance
ORDER BY 
    ranking;

