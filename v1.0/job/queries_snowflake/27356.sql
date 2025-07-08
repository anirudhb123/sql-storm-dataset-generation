
WITH MovieTitleKeywords AS (
    SELECT 
        a.title AS movie_title,
        k.keyword AS movie_keyword,
        a.production_year,
        a.id AS movie_id
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000  
),
PersonRoles AS (
    SELECT 
        c.movie_id,
        p.name AS actor_name,
        r.role AS role_title,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, p.name, r.role
),
MovieCompanyInfo AS (
    SELECT 
        m.movie_id,
        COUNT(m.id) AS company_count,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS companies_involved
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    GROUP BY 
        m.movie_id
),
RankedMovies AS (
    SELECT 
        mt.movie_title,
        pt.actor_name,
        pt.role_title,
        mc.company_count,
        mc.companies_involved,
        ROW_NUMBER() OVER (PARTITION BY mt.movie_title ORDER BY pt.role_count DESC) AS actor_rank
    FROM 
        MovieTitleKeywords mt
    JOIN 
        PersonRoles pt ON mt.movie_id = pt.movie_id
    JOIN 
        MovieCompanyInfo mc ON mt.movie_id = mc.movie_id
)
SELECT 
    movie_title,
    actor_name,
    role_title,
    company_count,
    companies_involved
FROM 
    RankedMovies
WHERE 
    actor_rank <= 3  
ORDER BY 
    movie_title, actor_rank;
