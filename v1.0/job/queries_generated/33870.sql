WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        1 AS level
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 1

    UNION ALL

    SELECT 
        ci2.person_id,
        ah.movie_count + COUNT(DISTINCT ci2.movie_id) AS movie_count,
        ah.level + 1
    FROM 
        cast_info ci2
    INNER JOIN 
        ActorHierarchy ah ON ci2.movie_id IN (
            SELECT 
                ci3.movie_id 
            FROM 
                cast_info ci3 
            WHERE 
                ci3.person_id = ah.person_id
        )
    GROUP BY 
        ci2.person_id, ah.movie_count, ah.level
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    AVG(t.production_year) AS avg_production_year,
    MAX(t.production_year) AS last_movie_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ak.name IS NOT NULL
    AND ak.name NOT LIKE '%*%'
GROUP BY 
    ak.id
HAVING 
    COUNT(DISTINCT c.movie_id) > 2
ORDER BY 
    movie_count DESC
LIMIT 10;

SELECT 
    a.name AS actor_name,
    CASE 
        WHEN a.gender IS NULL THEN 'Gender not specified'
        ELSE a.gender
    END AS gender,
    b.movie_title,
    b.production_year,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY b.production_year DESC) AS year_rank
FROM 
    aka_name a
INNER JOIN 
    (
        SELECT 
            t.title AS movie_title,
            t.production_year,
            ci.person_id
        FROM 
            cast_info ci
        JOIN 
            title t ON ci.movie_id = t.id
        WHERE 
            t.production_year >= 2000
    ) b ON a.person_id = b.person_id
WHERE 
    a.surname_pcode IS NULL
ORDER BY 
    a.name, year_rank;
