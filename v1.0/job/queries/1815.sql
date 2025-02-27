WITH MovieRoles AS (
    SELECT 
        c.movie_id, 
        r.role AS role_name, 
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
), 
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, co.name, ct.kind
), 
TopMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        mr.role_name,
        mr.actor_count,
        cd.company_name,
        cd.company_type,
        cd.total_companies,
        RANK() OVER (PARTITION BY mr.role_name ORDER BY mr.actor_count DESC) AS rank_by_actor_count
    FROM 
        aka_title mt
    JOIN 
        MovieRoles mr ON mt.id = mr.movie_id
    LEFT JOIN 
        CompanyDetails cd ON mt.id = cd.movie_id
    WHERE 
        mt.production_year > 2000
)
SELECT 
    t.title,
    t.production_year,
    t.role_name,
    t.actor_count,
    t.company_name,
    t.company_type,
    t.total_companies
FROM 
    TopMovies t
WHERE 
    t.rank_by_actor_count <= 5
ORDER BY 
    t.role_name, t.actor_count DESC;
