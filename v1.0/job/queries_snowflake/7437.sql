
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')
), MovieDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        LISTAGG(rm.actor_name, ', ') WITHIN GROUP (ORDER BY rm.actor_name) AS actors
    FROM 
        RankedMovies rm
    GROUP BY 
        rm.title, rm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.actors,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id IN (SELECT id FROM title WHERE title = md.title)) AS info_count
FROM 
    MovieDetails md
WHERE 
    md.production_year = (SELECT MAX(production_year) FROM MovieDetails)
ORDER BY 
    md.title;
