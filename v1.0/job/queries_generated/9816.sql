WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title, 
        t.production_year, 
        GROUP_CONCAT(DISTINCT c.name ORDER BY ci.nr_order) AS cast_names, 
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords, 
        COALESCE(COUNT(mc.id), 0) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS unique_companies,
        MAX(CASE WHEN ct.kind = 'Distributor' THEN 1 ELSE 0 END) AS has_distributor
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
    md.movie_title, 
    md.production_year, 
    md.cast_names, 
    md.keywords, 
    cd.unique_companies, 
    cd.has_distributor
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.id = cd.movie_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
