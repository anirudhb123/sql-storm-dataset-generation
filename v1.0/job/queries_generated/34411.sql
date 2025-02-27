WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.title LIKE 'A%'

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS year_rank
    FROM 
        MovieHierarchy mh
)
SELECT 
    ak.name AS actor_name,
    mv.title AS movie_title,
    mv.production_year,
    co.name AS company_name,
    rt.role AS role,
    COUNT(ci.id) AS total_cast,
    AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS is_director
FROM 
    cast_info ci
JOIN 
    name ak ON ci.person_id = ak.id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON ci.movie_id = mi.movie_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    TopMovies mv ON ci.movie_id = mv.movie_id
WHERE 
    mv.year_rank <= 5
GROUP BY 
    ak.name, mv.title, mv.production_year, co.name, rt.role
HAVING 
    COUNT(ci.id) > 1
ORDER BY 
    mv.production_year DESC, ak.name;
