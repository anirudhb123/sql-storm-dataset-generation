
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    GROUP BY 
        t.title, t.production_year
), ActorInfo AS (
    SELECT 
        a.name,
        a.surname_pcode,
        COUNT(DISTINCT ci.movie_id) AS movies_frequented,
        RANK() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name, a.surname_pcode
), Top3Movies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 3
)
SELECT 
    tm.title,
    tm.production_year,
    ai.name,
    ai.movies_frequented,
    COALESCE(ai.surname_pcode, 'N/A') AS surname_code,
    CASE 
        WHEN ai.actor_rank <= 10 THEN 'Top Actor'
        ELSE 'Supporting Actor'
    END AS actor_status
FROM 
    Top3Movies tm
LEFT JOIN 
    ActorInfo ai ON tm.actor_count = ai.movies_frequented
WHERE 
    tm.production_year >= (SELECT MAX(production_year) - 5 FROM aka_title)
ORDER BY 
    tm.production_year DESC, ai.movies_frequented DESC;
