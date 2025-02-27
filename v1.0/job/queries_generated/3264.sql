WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COALESCE(SUM(mi.info LIKE '%Award%') OVER (PARTITION BY at.id), 0) AS award_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, award_count DESC) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        movie_info mi ON at.id = mi.movie_id
    WHERE 
        at.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        award_count 
    FROM 
        RankedMovies 
    WHERE 
        year_rank <= 5
),
PersonMovies AS (
    SELECT 
        na.name AS actor_name,
        tm.title,
        tm.production_year,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci 
    JOIN 
        aka_name na ON ci.person_id = na.person_id
    JOIN 
        TopMovies tm ON ci.movie_id = tm.title
    GROUP BY 
        na.name, tm.title, tm.production_year
)
SELECT 
    pm.actor_name,
    STRING_AGG(DISTINCT pm.title, ', ') AS titles,
    SUM(pm.movie_count) AS total_titles,
    MAX(tm.production_year) AS latest_year
FROM 
    PersonMovies pm
JOIN 
    TopMovies tm ON pm.title = tm.title
GROUP BY 
    pm.actor_name
HAVING 
    SUM(pm.movie_count) > 1
ORDER BY 
    total_titles DESC, latest_year DESC;
