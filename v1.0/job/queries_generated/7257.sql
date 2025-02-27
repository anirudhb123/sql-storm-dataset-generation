WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        GROUP_CONCAT(DISTINCT c.name) AS cast_members, 
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id AND ci.person_id = cc.subject_id
    JOIN 
        aka_name an ON an.person_id = ci.person_id
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id, 
        GROUP_CONCAT(DISTINCT cn.name) AS companies, 
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
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
    md.movie_id, 
    md.movie_title, 
    md.production_year, 
    md.cast_members, 
    md.keywords, 
    cd.companies, 
    cd.company_types
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
