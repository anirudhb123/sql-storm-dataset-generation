WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopActors AS (
    SELECT 
        ca.person_id,
        ka.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ka ON ka.person_id = ci.person_id
    GROUP BY 
        ca.person_id, ka.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) >= 5
),
MovieDetails AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        GROUP_CONCAT(DISTINCT ka.actor_name ORDER BY ka.actor_name ASC) AS actors
    FROM 
        RankedTitles mt
    JOIN 
        cast_info ci ON ci.movie_id = mt.title_id
    JOIN 
        TopActors ka ON ka.person_id = ci.person_id
    GROUP BY 
        mt.movie_id, mt.title, mt.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.actors
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, md.title ASC;

This query benchmarks string processing by fetching titles of movies produced between 2000 and 2020 along with the names of actors who have appeared in at least five movies. It uses Common Table Expressions (CTEs) for organized data handling and aggregation, employing string functions and joins to assemble the final result set.
