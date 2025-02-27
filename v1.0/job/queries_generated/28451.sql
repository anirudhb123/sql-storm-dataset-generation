WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS role_type,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type c ON ci.role_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        t.id, a.name, c.kind
), CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS num_cast_members
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        complete_cast cc ON mc.movie_id = cc.movie_id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.role_type,
    md.keyword_count,
    md.keywords,
    cd.company_name,
    cd.company_type,
    cd.num_cast_members
FROM 
    MovieDetails md
JOIN 
    CompanyDetails cd ON md.movie_title = cd.movie_id
ORDER BY 
    md.production_year DESC, md.keyword_count DESC;
