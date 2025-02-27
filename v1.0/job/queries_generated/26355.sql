WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS companies,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name) AS actors
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id 
    WHERE 
        t.production_year BETWEEN 1990 AND 2023
        AND k.keyword LIKE '%action%' 
    GROUP BY 
        t.id
),
RoleInfo AS (
    SELECT 
        ci.movie_id,
        r.role,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
),
FilteredMovieDetails AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.companies,
        COUNT(DISTINCT r.role) AS role_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        RoleInfo r ON md.movie_id = r.movie_id
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.keywords, md.companies
)
SELECT 
    movie_id,
    title,
    production_year,
    keywords,
    companies,
    role_count
FROM 
    FilteredMovieDetails
ORDER BY 
    production_year DESC, role_count DESC;
