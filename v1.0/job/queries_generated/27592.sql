WITH MovieKeywords AS (
    SELECT 
        mt.movie_id,
        string_agg(kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    JOIN 
        aka_title AS mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id
),
MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        ARRAY_AGG(DISTINCT co.name) AS companies
    FROM 
        aka_title AS mt
    LEFT JOIN 
        MovieKeywords AS mk ON mt.id = mk.movie_id
    LEFT JOIN 
        movie_companies AS mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name AS co ON mc.company_id = co.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        string_agg(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info AS ci
    JOIN 
        role_type AS r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    COALESCE(ar.roles, 'No Roles') AS roles,
    coalesce(md.companies, '{}') AS companies
FROM 
    MovieDetails AS md
LEFT JOIN 
    ActorRoles AS ar ON md.movie_id = ar.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title;
