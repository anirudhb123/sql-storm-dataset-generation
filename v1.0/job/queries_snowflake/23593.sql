
WITH RecursiveHierarchy AS (
    SELECT 
        c.id AS company_id,
        c.name AS company_name,
        c.country_code,
        COALESCE(mc.note, 'No Notes') AS company_note,
        ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY mc.company_type_id DESC) AS rank
    FROM 
        company_name c
    LEFT JOIN 
        movie_companies mc ON c.id = mc.company_id
    WHERE 
        c.country_code IS NOT NULL
    AND 
        c.name IS NOT NULL
),
SelectedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ki.id) AS keyword_count,
        RANK() OVER (ORDER BY m.production_year DESC) AS movie_rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(DISTINCT ki.id) > 5
),
CastInfo AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        ro.role,
        COUNT(*) OVER (PARTITION BY ca.person_id) AS role_count
    FROM 
        cast_info ca
    JOIN 
        role_type ro ON ca.role_id = ro.id
    WHERE 
        ca.note IS NOT NULL
),
AggregatedRoleCounts AS (
    SELECT 
        person_id,
        SUM(role_count) AS total_roles
    FROM 
        CastInfo
    GROUP BY 
        person_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ca.total_roles, 0) AS total_roles_by_person,
    rh.company_name,
    rh.company_note,
    mh.keyword_count,
    CASE 
        WHEN mh.production_year >= 2000 
        THEN 'Modern' 
        ELSE 'Classic' 
    END AS movie_era
FROM 
    SelectedMovies mh
LEFT JOIN 
    AggregatedRoleCounts ca ON mh.movie_id = ca.person_id 
LEFT JOIN 
    RecursiveHierarchy rh ON mh.movie_id = rh.company_id
WHERE 
    mh.keyword_count IS NOT NULL 
AND 
    (rh.country_code IS NULL OR rh.country_code = 'US')
ORDER BY 
    mh.production_year DESC, 
    total_roles_by_person DESC
LIMIT 50;
