
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS role_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id 
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorRoles AS (
    SELECT 
        ak.id AS aka_id,
        ak.name,
        c.movie_id,
        r.role,
        COUNT(c.nr_order) AS role_count
    FROM 
        aka_name ak
    INNER JOIN 
        cast_info c ON ak.person_id = c.person_id
    INNER JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        ak.id, ak.name, c.movie_id, r.role
),
KeyRoleCount AS (
    SELECT 
        ar.movie_id,
        SUM(ar.role_count) AS total_roles,
        LISTAGG(DISTINCT ar.role, ', ') WITHIN GROUP (ORDER BY ar.role) AS role_list
    FROM 
        ActorRoles ar
    GROUP BY 
        ar.movie_id
),
CompanyTypes AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.name) AS company_count,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    RM.movie_id,
    RM.title,
    RM.production_year,
    COALESCE(KRC.total_roles, 0) AS total_roles,
    COALESCE(KRC.role_list, 'No roles available') AS roles,
    COALESCE(CT.company_count, 0) AS company_count,
    COALESCE(CT.companies, 'No companies listed') AS companies
FROM 
    RankedMovies RM
LEFT JOIN 
    KeyRoleCount KRC ON RM.movie_id = KRC.movie_id
LEFT JOIN 
    CompanyTypes CT ON RM.movie_id = CT.movie_id
WHERE 
    RM.role_rank = 1
    AND RM.production_year IS NOT NULL
ORDER BY 
    RM.production_year DESC, 
    total_roles DESC;
