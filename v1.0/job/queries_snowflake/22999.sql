
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year > 2000  

    UNION ALL

    SELECT
        mc.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1 AS depth
    FROM
        movie_link mc
    JOIN
        aka_title mt ON mt.id = mc.linked_movie_id
    JOIN
        movie_hierarchy mh ON mh.movie_id = mc.movie_id
)
SELECT 
    na.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(ct.kind) AS comp_cast_count,
    SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count,
    LISTAGG(DISTINCT ki.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY na.person_id ORDER BY at.production_year DESC) AS actor_rank
FROM 
    aka_name na
JOIN 
    cast_info ci ON ci.person_id = na.person_id
JOIN 
    aka_title at ON at.id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = at.id
LEFT JOIN 
    keyword ki ON ki.id = mk.keyword_id
JOIN 
    comp_cast_type ct ON ct.id = ci.person_role_id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = at.id
JOIN 
    movie_info mi ON mi.movie_id = at.id
WHERE 
    na.name IS NOT NULL
    AND at.production_year IS NOT NULL
    AND (at.note IS NULL OR at.note != 'Unreleased')  
    AND EXISTS (
        SELECT 1
        FROM complete_cast c
        WHERE c.movie_id = at.id 
        AND c.subject_id = na.person_id
    )
    AND NOT EXISTS (
        SELECT 1
        FROM aka_name an
        WHERE an.person_id = na.person_id
        AND LENGTH(an.name) < 5  
    )
GROUP BY 
    na.name, na.person_id, at.title, at.production_year, actor_rank
HAVING 
    COUNT(ct.kind) > 2  
ORDER BY
    actor_rank, at.production_year DESC
LIMIT 50;
