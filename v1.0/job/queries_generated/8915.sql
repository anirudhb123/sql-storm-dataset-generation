WITH RecursiveMovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level
    FROM 
        title t
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        rm.level + 1
    FROM 
        RecursiveMovieHierarchy rm
    JOIN 
        movie_link ml ON rm.movie_id = ml.movie_id
    JOIN 
        title t ON ml.linked_movie_id = t.id
    WHERE 
        t.production_year >= 2000
)

SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    ak.name AS actor_name,
    cct.kind AS comp_cast_type,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    RecursiveMovieHierarchy r
JOIN 
    complete_cast cc ON r.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    comp_cast_type cct ON ci.person_role_id = cct.id
JOIN 
    movie_keyword mk ON r.movie_id = mk.movie_id
WHERE 
    r.level <= 1
GROUP BY 
    r.movie_id, r.title, r.production_year, ak.name, cct.kind
ORDER BY 
    r.production_year DESC, keyword_count DESC;
