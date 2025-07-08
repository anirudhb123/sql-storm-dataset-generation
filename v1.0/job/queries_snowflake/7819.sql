
WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        c.person_id,
        n.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY a.name) AS rank_within_year
    FROM 
        aka_name a
    INNER JOIN 
        aka_title t ON a.id = t.id
    INNER JOIN 
        cast_info c ON t.id = c.movie_id
    INNER JOIN 
        name n ON c.person_id = n.id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredRankedMovies AS (
    SELECT 
        rm.* 
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_within_year <= 5
)
SELECT 
    fr.movie_title,
    fr.production_year,
    LISTAGG(fr.actor_name, ', ') WITHIN GROUP (ORDER BY fr.actor_name) AS top_actors
FROM 
    FilteredRankedMovies fr
GROUP BY 
    fr.movie_title, fr.production_year
ORDER BY 
    fr.production_year DESC, fr.movie_title;
