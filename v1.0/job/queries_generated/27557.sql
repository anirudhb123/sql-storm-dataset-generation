WITH RecursiveNameList AS (
    SELECT 
        ak.name AS aka_name,
        p.id AS person_id,
        r.role AS person_role,
        m.title AS movie_title,
        m.production_year AS movie_year,
        ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY m.production_year DESC) AS rn
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title m ON ci.movie_id = m.id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        name p ON ak.person_id = p.imdb_id
    WHERE 
        ak.name IS NOT NULL AND 
        m.production_year IS NOT NULL
),
FilteredNames AS (
    SELECT 
        aka_name,
        person_id,
        person_role,
        movie_title,
        movie_year
    FROM 
        RecursiveNameList
    WHERE 
        rn <= 5
),
AggregateRoles AS (
    SELECT 
        person_id,
        STRING_AGG(DISTINCT person_role, ', ') AS roles,
        COUNT(DISTINCT movie_title) AS movie_count,
        MIN(movie_year) AS first_movie_year,
        MAX(movie_year) AS last_movie_year
    FROM 
        FilteredNames
    GROUP BY 
        person_id
)
SELECT 
    p.name AS full_name,
    an.aka_name,
    ar.roles,
    ar.movie_count,
    ar.first_movie_year,
    ar.last_movie_year
FROM 
    AggregateRoles ar
JOIN 
    aka_name an ON ar.person_id = an.person_id
JOIN 
    name p ON ar.person_id = p.imdb_id
WHERE 
    ar.movie_count > 3
ORDER BY 
    ar.movie_count DESC, 
    last_movie_year DESC;
