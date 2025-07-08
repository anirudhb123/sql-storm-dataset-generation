
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 3
),
ActorsWithTopMovies AS (
    SELECT 
        a.name,
        tm.title,
        tm.production_year
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS ci ON a.person_id = ci.person_id
    JOIN 
        TopMovies AS tm ON ci.movie_id = (SELECT movie_id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors
    FROM 
        TopMovies AS tm
    LEFT JOIN 
        ActorsWithTopMovies AS a ON tm.title = a.title AND tm.production_year = a.production_year
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actors, 'No actors listed') AS actor_list
FROM 
    MovieDetails AS md
LEFT JOIN 
    movie_info AS mi ON md.title = mi.info AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
WHERE 
    (md.production_year IS NOT NULL AND md.production_year > 2000)
ORDER BY 
    md.production_year DESC;
