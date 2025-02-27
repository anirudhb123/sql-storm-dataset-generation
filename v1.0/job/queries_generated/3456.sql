WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        K.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword K ON mk.keyword_id = K.id
    WHERE 
        a.production_year IS NOT NULL
),
CriticalActors AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role IN ('Lead', 'Supporting')
    GROUP BY 
        c.movie_id
)
SELECT 
    RM.title,
    RM.production_year,
    COALESCE(CA.actor_count, 0) AS total_actors,
    STRING_AGG(DISTINCT K.keyword, ', ') AS keywords
FROM 
    RankedMovies RM
LEFT JOIN 
    CriticalActors CA ON RM.id = CA.movie_id
LEFT JOIN 
    movie_keyword MK ON RM.id = MK.movie_id
LEFT JOIN 
    keyword K ON MK.keyword_id = K.id
WHERE 
    RM.year_rank <= 5
GROUP BY 
    RM.title, RM.production_year, CA.actor_count
ORDER BY 
    RM.production_year DESC, RM.title;
