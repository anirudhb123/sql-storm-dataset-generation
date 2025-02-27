
WITH movie_details AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ak.imdb_index AS actor_index,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
        AND ak.name IS NOT NULL
    GROUP BY 
        mt.title, mt.production_year, ak.name, ak.imdb_index
),
actor_roles AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.actor_index,
    ar.movie_count,
    ar.roles,
    md.keywords
FROM 
    movie_details md
JOIN 
    actor_roles ar ON md.actor_name = ar.actor_name
ORDER BY 
    md.production_year DESC, ar.movie_count DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
