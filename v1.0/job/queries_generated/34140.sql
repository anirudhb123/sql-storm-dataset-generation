WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),

PopularActors AS (
    SELECT 
        ka.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    WHERE 
        ka.name IS NOT NULL
    GROUP BY 
        ka.name
    HAVING 
        COUNT(ci.movie_id) > 5
),

CompanyDetails AS (
    SELECT 
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.movie_id) AS produced_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        cn.name, ct.kind
    HAVING 
        COUNT(mc.movie_id) > 10
)

SELECT 
    mh.movie_title,
    mh.production_year,
    ma.actor_name,
    ma.movie_count AS actor_movie_count,
    cd.company_name,
    cd.company_type,
    cd.produced_movies
FROM 
    MovieHierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    PopularActors ma ON ci.person_id = ma.person_id
LEFT OUTER JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT OUTER JOIN 
    CompanyDetails cd ON mc.company_id = cd.company_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
    AND (cd.produced_movies IS NULL OR cd.produced_movies > 5)
ORDER BY 
    mh.production_year DESC, actor_movie_count DESC;
