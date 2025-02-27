WITH RecursiveFilmography AS (
    SELECT 
        ak.id AS aka_id,
        ak.name AS aka_name,
        ak.person_id,
        ct.kind AS person_role,
        COALESCE(t.production_year, 'Unknown') AS production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name ak
    LEFT JOIN cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN aka_title t ON ci.movie_id = t.id
    LEFT JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        ak.name IS NOT NULL AND ak.name <> ''
),
DistinctRoles AS (
    SELECT 
        DISTINCT person_id, 
        person_role 
    FROM 
        RecursiveFilmography
),
RoleCount AS (
    SELECT 
        person_id,
        COUNT(DISTINCT person_role) AS total_roles
    FROM 
        DistinctRoles
    GROUP BY 
        person_id
),
TopActors AS (
    SELECT 
        r.aka_name,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        SUM(CASE 
            WHEN r.production_year = 'Unknown' THEN 1 
            ELSE 0 
        END) AS unknown_years,
        COALESCE(AVG(NULLIF(length(r.aka_name), 0)), 0) AS average_name_length
    FROM 
        RecursiveFilmography r
    JOIN 
        RoleCount rc ON r.person_id = rc.person_id
    GROUP BY 
        r.aka_name
)
SELECT 
    a.aka_name,
    a.total_movies,
    a.unknown_years,
    rc.total_roles,
    CASE 
        WHEN a.average_name_length IS NULL THEN 'No Data' 
        ELSE a.average_name_length::text 
    END AS average_length_postfix
FROM 
    TopActors a
LEFT JOIN 
    RoleCount rc ON a.aka_name = rc.person_id::text
ORDER BY 
    total_movies DESC,
    average_name_length DESC 
LIMIT 10;

