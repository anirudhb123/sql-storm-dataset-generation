
WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        0 AS hierarchy_level
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.movie_id IN (SELECT id FROM aka_title WHERE title LIKE '%Star Wars%')
    
    UNION ALL
    
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        ah.hierarchy_level + 1
    FROM 
        actor_hierarchy ah
    JOIN 
        cast_info ci ON ci.movie_id IN (
            SELECT linked_movie_id 
            FROM movie_link 
            WHERE movie_id = (SELECT movie_id FROM movie_companies WHERE company_id IN (
                SELECT id FROM company_name WHERE country_code = 'USA'
            ))
        )
    JOIN 
        aka_name a ON ci.person_id = a.person_id
)
SELECT 
    actor_hierarchy.actor_name,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    MAX(at.production_year) AS latest_movie_year,
    LISTAGG(DISTINCT at.title, ', ') WITHIN GROUP (ORDER BY at.title) AS movies,
    AVG(CASE 
            WHEN mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'box office') 
            THEN CAST(mi.info AS FLOAT)
            ELSE NULL 
        END) AS avg_box_office,
    COUNT(DISTINCT kw.keyword) AS keyword_count
FROM 
    actor_hierarchy
JOIN 
    cast_info ci ON actor_hierarchy.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
LEFT JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON ci.movie_id = mi.movie_id
GROUP BY 
    actor_hierarchy.actor_name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5 AND MAX(at.production_year) > 2000
ORDER BY 
    movie_count DESC, latest_movie_year DESC;
