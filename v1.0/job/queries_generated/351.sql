WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS movie_rank
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        movie_rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    (SELECT COUNT(DISTINCT ci.person_id) 
     FROM cast_info ci 
     WHERE ci.movie_id = tm.movie_id) AS actor_count,
    (SELECT STRING_AGG(DISTINCT an.name, ', ') 
     FROM identifier an 
     LEFT JOIN person_info pi ON an.id = pi.person_id 
     WHERE pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Birthdate')
       AND pi.info IS NOT NULL) AS actor_birthdates
FROM 
    TopMovies tm 
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id 
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre') 
    AND (mi.info LIKE '%Drama%' OR mi.info LIKE '%Comedy%')
ORDER BY 
    tm.production_year DESC, 
    actor_count DESC;
