WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedTitles 
    WHERE 
        rank <= 3
)
SELECT 
    DISTINCT 
    ak.name AS actor_name, 
    STRING_AGG(tt.title, ', ') AS titles,
    COUNT(tt.title) AS title_count,
    AVG(COALESCE(mv.production_year, 0)) AS avg_prod_year
FROM 
    aka_name ak
LEFT JOIN cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN TopMovies tt ON ci.movie_id = tt.title
LEFT JOIN title mv ON mv.title = tt.title
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(tt.title) > 0
ORDER BY 
    title_count DESC;
