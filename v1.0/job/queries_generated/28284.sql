WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.id AS cast_id,
        p.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        c.nr_order,
        r.role
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(cn.name) AS company_names,
        GROUP_CONCAT(ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cd.actor_name,
    cd.nr_order,
    GROUP_CONCAT(DISTINCT cm.company_names) AS associated_companies,
    GROUP_CONCAT(DISTINCT cm.company_types) AS associated_company_types
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.rank_by_year <= 10  -- Limiting to top 10 movies per year
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, cd.actor_name, cd.nr_order
ORDER BY 
    rm.production_year DESC, rm.movie_id;
