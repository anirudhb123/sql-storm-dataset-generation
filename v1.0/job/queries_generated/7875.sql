WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank 
    FROM 
        aka_title t 
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id 
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    WHERE 
        k.keyword LIKE '%action%' 
    AND 
        t.production_year >= 2000
),
TopActors AS (
    SELECT 
        a.name, 
        COUNT(ci.movie_id) AS movie_count 
    FROM 
        aka_name a 
    JOIN 
        cast_info ci ON a.person_id = ci.person_id 
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id 
    GROUP BY 
        a.name 
    HAVING 
        movie_count > 5
)
SELECT 
    rm.title, 
    rm.production_year, 
    ta.name AS actor_name, 
    ta.movie_count 
FROM 
    RankedMovies rm 
JOIN 
    TopActors ta ON rm.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = (SELECT id FROM aka_name WHERE name = ta.name)) 
WHERE 
    rm.year_rank <= 10 
ORDER BY 
    rm.production_year DESC, 
    ta.movie_count DESC;
