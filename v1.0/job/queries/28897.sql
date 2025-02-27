
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS actor_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS actor_names
    FROM 
        title
    INNER JOIN 
        movie_info ON title.id = movie_info.movie_id
    INNER JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    INNER JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    INNER JOIN 
        cast_info ON title.id = cast_info.movie_id
    INNER JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        movie_info.info_type_id IN (SELECT id FROM info_type WHERE info = 'Description')
        AND title.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        title.id, title.title, title.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        actor_names,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.actor_names,
    COUNT(DISTINCT mc.company_id) AS production_companies_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS production_company_names
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.actor_count, tm.actor_names, tm.rank
ORDER BY 
    tm.rank;
