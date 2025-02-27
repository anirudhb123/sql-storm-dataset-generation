WITH MovieRankings AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        MovieRankings
    WHERE 
        rn <= 5
),
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        a.production_year,
        t.title,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY ak.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    JOIN 
        TopMovies a ON t.title = a.title AND t.production_year = a.production_year
)
SELECT 
    ai.actor_name,
    ai.title AS movie_title,
    ai.production_year,
    COALESCE(mk.keyword, 'No Keyword') AS movie_keyword,
    CASE 
        WHEN ai.actor_rank <= 3 THEN 'Featured Actor'
        ELSE 'Supporting Actor'
    END AS actor_type
FROM 
    ActorInfo ai
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = ai.movie_title AND production_year = ai.production_year LIMIT 1)
WHERE 
    ai.actor_rank <= 10
ORDER BY 
    ai.production_year DESC, ai.actor_rank ASC;
