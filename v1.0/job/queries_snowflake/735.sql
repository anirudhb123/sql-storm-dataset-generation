
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names,
        COALESCE(md.info, 'No info available') AS additional_info
    FROM 
        TopMovies tm
    JOIN 
        cast_info c ON c.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_info md ON md.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
    GROUP BY 
        tm.title, tm.production_year, md.info
)
SELECT 
    md.title,
    md.production_year,
    md.actor_names,
    md.additional_info
FROM 
    MovieDetails md
WHERE 
    md.additional_info IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title ASC
LIMIT 10;
