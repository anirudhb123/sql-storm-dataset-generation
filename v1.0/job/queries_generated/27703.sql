WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
)

SELECT 
    p.name AS person_name,
    rt.aka_name,
    rt.movie_title,
    rt.production_year
FROM 
    RankedTitles rt
JOIN 
    name p ON rt.aka_id = p.imdb_id
WHERE 
    rt.title_rank <= 3
ORDER BY 
    p.name, rt.production_year DESC;

-- The following query retrieves the top 3 most recent titles for each individual,
-- along with their names and corresponding movie title/production year. 
-- It demonstrates a complex join operation while ranking the titles per person.
