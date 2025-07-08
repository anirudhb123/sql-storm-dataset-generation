
WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        a.md5sum AS actor_md5sum,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id IN (SELECT id FROM aka_title WHERE production_year = 2023)
    
    UNION ALL

    SELECT 
        c.person_id,
        a.name,
        a.md5sum,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON c.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id)
)

SELECT 
    ah.actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    LISTAGG(DISTINCT t.title, ', ') WITHIN GROUP (ORDER BY t.title) AS movies,
    AVG(m.production_year) AS avg_production_year,
    MAX(m.production_year) AS latest_movie_year,
    MIN(m.production_year) AS earliest_movie_year,
    COUNT(DISTINCT CASE WHEN c.note IS NOT NULL THEN c.movie_id END) AS movies_with_notes,
    CASE 
        WHEN COUNT(DISTINCT c.movie_id) > 10 THEN 'Prolific Actor'
        ELSE 'Emerging Actor'
    END AS actor_status,
    COALESCE(SUM(CASE WHEN mi.info LIKE '%award%' THEN 1 ELSE 0 END), 0) AS awards_info,
    COALESCE(SUM(CASE WHEN c.nr_order = 1 THEN 1 ELSE 0 END), 0) AS leading_roles,
    COALESCE(NULLIF(MAX(m.production_year) - MIN(m.production_year), 0), NULL) AS year_gap
FROM 
    ActorHierarchy ah
JOIN 
    cast_info c ON ah.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
JOIN 
    title m ON t.id = m.id
GROUP BY 
    ah.actor_name, ah.actor_md5sum
HAVING 
    AVG(m.production_year) < 2022 
ORDER BY 
    total_movies DESC, latest_movie_year DESC;
