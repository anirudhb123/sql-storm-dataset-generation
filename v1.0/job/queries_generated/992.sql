WITH RankedMovies AS (
    SELECT 
        movie.title AS movie_title,
        movie.production_year,
        COUNT(DISTINCT cast.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY movie.production_year ORDER BY COUNT(DISTINCT cast.person_id) DESC) AS rn
    FROM 
        aka_title movie
    LEFT JOIN 
        cast_info cast ON movie.id = cast.movie_id
    GROUP BY 
        movie.title, movie.production_year
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year
    FROM 
        RankedMovies 
    WHERE 
        rn <= 5
),
MovieKeywords AS (
    SELECT 
        movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON keyword.id = movie_keyword.keyword_id
    GROUP BY 
        movie_id
)
SELECT 
    tm.movie_title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords Listed') AS movie_keywords,
    COALESCE(ak.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT CASE WHEN ci.role_id IS NOT NULL THEN ci.person_id END) AS unique_actor_roles
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON mi.movie_id IN (SELECT id FROM aka_title WHERE title = tm.movie_title)
LEFT JOIN 
    movie_keyword mk ON mk.movie_id IN (SELECT id FROM aka_title WHERE title = tm.movie_title)
LEFT JOIN 
    cast_info ci ON ci.movie_id IN (SELECT id FROM aka_title WHERE title = tm.movie_title)
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
WHERE 
    tm.production_year >= 2000
GROUP BY 
    tm.movie_title, tm.production_year, mk.keywords, ak.name
ORDER BY 
    tm.production_year DESC, actor_count DESC;
