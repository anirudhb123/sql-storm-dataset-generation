WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        a.md5sum,
        a.imdb_index,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.movie_id IN (SELECT movie_id FROM aka_title WHERE production_year >= 2000)
    
    UNION ALL
    
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        a.md5sum,
        a.imdb_index,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON ci.movie_id IN (SELECT movie_id FROM complete_cast WHERE subject_id = ah.person_id)
)
SELECT 
    actor.actor_name,
    COUNT(ct.id) AS total_movies,
    AVG(mt.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY actor.actor_name ORDER BY COUNT(ct.id) DESC) AS row_num
FROM 
    ActorHierarchy actor
JOIN 
    complete_cast cc ON cc.subject_id = actor.person_id
JOIN 
    aka_title mt ON mt.movie_id = cc.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mt.id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    cast_info ct ON ct.person_id = actor.person_id
WHERE 
    actor.level <= 3
GROUP BY 
    actor.actor_name, actor.md5sum, actor.imdb_index
HAVING 
    COUNT(ct.id) > 5
ORDER BY 
    avg_production_year DESC, total_movies DESC;

This query performs comprehensive performance benchmarking by utilizing a recursive common table expression (CTE) to build an actor hierarchy that includes actors connected to movies post-2000. It aggregates data about the total number of movies each actor has participated in, calculates the average production year of their films, and collects associated keywords. It incorporates window functions to rank each actor based on the number of movies while also applying filtering and joining across multiple tables with LEFT JOINs and subqueries for additional contextual data. The final output is ordered by average production year and the total number of films in descending order.
