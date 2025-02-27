WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title AS title,
        t.production_year,
        c.kind AS company_type,
        ARRAY[t.title] AS path_titles
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        t.title,
        t.production_year,
        c.kind AS company_type,
        path_titles || t.title
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        title t ON ml.linked_movie_id = t.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year >= 2000
),
MovieCounts AS (
    SELECT 
        movie_id,
        COUNT(*) AS num_titles,
        STRING_AGG(DISTINCT title, ', ') AS all_titles
    FROM 
        MovieHierarchy
    GROUP BY 
        movie_id
),
PersonRoles AS (
    SELECT 
        ai.person_id,
        ci.movie_id,
        rt.role 
    FROM 
        cast_info ci
    JOIN 
        aka_name ai ON ci.person_id = ai.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
)
SELECT 
    m.title,
    m.production_year,
    m.num_titles,
    m.all_titles,
    COUNT(pr.person_id) AS num_actors,
    STRING_AGG(DISTINCT pr.role, ', ') AS roles
FROM 
    MovieCounts m
LEFT JOIN 
    PersonRoles pr ON m.movie_id = pr.movie_id
GROUP BY 
    m.movie_id, m.title, m.production_year, m.num_titles, m.all_titles
ORDER BY 
    m.production_year DESC, num_titles DESC;
