WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        GROUP_CONCAT(DISTINCT k.keyword SEPARATOR ', ') AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
CompanyProduction AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name SEPARATOR ', ') AS companies,
        GROUP_CONCAT(DISTINCT ct.kind SEPARATOR ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        GROUP_CONCAT(DISTINCT r.role ORDER BY c.nr_order SEPARATOR ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.keywords,
    md.cast_count,
    cp.companies,
    cp.company_types,
    ar.roles
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyProduction cp ON md.movie_id = cp.movie_id
LEFT JOIN 
    ActorRoles ar ON md.movie_id = ar.movie_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
