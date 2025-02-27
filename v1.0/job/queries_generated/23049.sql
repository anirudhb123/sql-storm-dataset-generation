WITH RecursiveMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ai.person_id,
        ai.role_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        role_type ai ON ci.role_id = ai.id
    GROUP BY 
        ai.person_id, ai.role_id
),
TopActors AS (
    SELECT 
        ar.person_id,
        ar.role_id,
        ar.movie_count,
        RANK() OVER (ORDER BY ar.movie_count DESC) AS actor_rank
    FROM 
        ActorRoles ar
    WHERE 
        ar.movie_count > 2
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    ct.kind AS comp_type,
    COUNT(DISTINCT mc.id) AS total_companies,
    ARRAY_AGG(DISTINCT c.name) AS company_names,
    CASE 
        WHEN mt.production_year < 2000 THEN 'Classic'
        WHEN mt.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    RecursiveMovies mt ON ci.movie_id = mt.movie_id 
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mt.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    TopActors ta ON ak.person_id = ta.person_id
WHERE 
    ak.name IS NOT NULL 
    AND (ct.kind IS NOT NULL OR mt.production_year IS NULL)
GROUP BY 
    ak.name, mt.title, mt.production_year, ct.kind
HAVING 
    COUNT(DISTINCT mc.id) > 0
    AND MAX(mt.title) IS NOT NULL
ORDER BY 
    mt.production_year DESC, actor_name;
