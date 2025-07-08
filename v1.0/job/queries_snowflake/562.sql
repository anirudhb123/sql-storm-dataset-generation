WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), 
AllActors AS (
    SELECT 
        a.name,
        a.person_id,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name, a.person_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(aa.movies_count, 0) AS movies_count,
    rm.actor_count,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id IN (SELECT id FROM aka_title WHERE production_year = rm.production_year)) AS info_count
FROM 
    RankedMovies rm
LEFT JOIN 
    AllActors aa ON rm.actor_count = aa.movies_count
WHERE 
    rm.rn <= 5
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
