WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title,
        mt.production_year,
        COALESCE(ka.name, 'Unknown') AS actor_name,
        COUNT(cc.id) OVER(PARTITION BY mt.id) AS actor_count
    FROM 
        aka_title AS mt
    LEFT JOIN 
        cast_info AS cc ON cc.movie_id = mt.id
    LEFT JOIN 
        aka_name AS ka ON ka.person_id = cc.person_id
    WHERE 
        mt.production_year >= 2000
        AND mt.kind_id IN (
            SELECT 
                kt.id 
            FROM 
                kind_type kt 
            WHERE 
                kt.kind LIKE 'feature%'
        )
),
FilteredMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        actor_name, 
        actor_count
    FROM 
        RecursiveMovieCTE 
    WHERE 
        actor_count > 0
)
SELECT 
    f.title,
    f.production_year,
    STRING_AGG(f.actor_name, ', ') AS actor_names,
    COUNT(DISTINCT f.actor_name) AS unique_actors,
    (SELECT COUNT(DISTINCT mc.company_id) 
     FROM movie_companies mc 
     WHERE mc.movie_id = f.movie_id) AS company_count,
    (SELECT 
         string_agg(p.info, ', ') 
     FROM 
         person_info p 
     WHERE 
         p.person_id IN (SELECT DISTINCT c.person_id FROM cast_info c WHERE c.movie_id = f.movie_id)) AS actors_info
FROM 
    FilteredMovies f
GROUP BY 
    f.title, f.production_year
ORDER BY 
    f.production_year DESC, unique_actors DESC
LIMIT 10;
