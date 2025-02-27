WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a 
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    INNER JOIN 
        TopMovies tm ON ci.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
    GROUP BY 
        ci.person_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT ci.movie_id) AS total_movies,
    COALESCE(AMC.movie_count, 0) AS top_movies_count
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    ActorMovieCounts AMC ON ak.person_id = AMC.person_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, AMC.movie_count
HAVING 
    SUM(CASE WHEN ci.movie_id IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY 
    total_movies DESC, actor_name ASC
LIMIT 10;
