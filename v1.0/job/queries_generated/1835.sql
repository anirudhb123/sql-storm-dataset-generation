WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
HighActorMovies AS (
    SELECT 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        actor_count > 5
)
SELECT 
    hm.title,
    hm.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    STRING_AGG(DISTINCT c.name, ', ') AS actor_names
FROM 
    HighActorMovies hm
LEFT JOIN 
    movie_keyword mk ON hm.title = (SELECT title FROM aka_title WHERE production_year = hm.production_year AND title = hm.title)
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    cast_info ci ON hm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
LEFT JOIN 
    aka_name c ON ci.person_id = c.person_id
WHERE 
    hm.production_year IS NOT NULL
GROUP BY 
    hm.title, hm.production_year
HAVING 
    COUNT(DISTINCT kc.keyword) > 2
ORDER BY 
    hm.production_year DESC, keyword_count DESC;
