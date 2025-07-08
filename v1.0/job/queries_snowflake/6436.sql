WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT cas.person_id) AS actor_count,
        AVG(CASE WHEN t.production_year >= 2000 THEN 1 ELSE 0 END) AS modern_ratio
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info cas ON cc.subject_id = cas.id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighActorMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        rm.modern_ratio
    FROM 
        RankedMovies rm
    WHERE 
        rm.actor_count > 10
)
SELECT 
    ham.title,
    ham.production_year,
    ham.actor_count,
    ham.modern_ratio,
    cn.name AS company_name
FROM 
    HighActorMovies ham
JOIN 
    movie_companies mc ON mc.movie_id = (SELECT id FROM title WHERE title = ham.title AND production_year = ham.production_year)
JOIN 
    company_name cn ON mc.company_id = cn.id
ORDER BY 
    ham.actor_count DESC, ham.production_year ASC
LIMIT 50;
