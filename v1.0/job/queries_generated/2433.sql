WITH MovieYearRanking AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title_id, title, production_year
    FROM 
        MovieYearRanking
    WHERE 
        year_rank <= 5
),
ActorStats AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ai.movie_id) AS movie_count,
        AVG(mk.id) AS average_keyword_id
    FROM 
        aka_name ak
    JOIN 
        cast_info ai ON ak.person_id = ai.person_id
    LEFT JOIN 
        movie_keyword mk ON ai.movie_id = mk.movie_id
    GROUP BY 
        ak.name
)
SELECT 
    t.title,
    t.production_year,
    a.actor_name,
    a.movie_count,
    a.average_keyword_id,
    COUNT(DISTINCT mk.keyword) AS total_keywords
FROM 
    TopMovies t
JOIN 
    cast_info ci ON t.title_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON t.title_id = mk.movie_id
GROUP BY 
    t.title, t.production_year, a.actor_name, a.movie_count, a.average_keyword_id
HAVING 
    total_keywords IS NOT NULL AND total_keywords > 0
ORDER BY 
    t.production_year DESC, a.movie_count DESC;
