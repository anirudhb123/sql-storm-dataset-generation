WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title ak 
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),

CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        cast_info c 
    JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        c.movie_id
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc 
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    md.title_id,
    md.title,
    md.production_year,
    md.kind_id,
    md.aka_names,
    cd.total_cast_members,
    cd.cast_names,
    comp.companies,
    comp.company_types
FROM 
    MovieDetails md
LEFT JOIN 
    CastDetails cd ON md.title_id = cd.movie_id
LEFT JOIN 
    CompanyDetails comp ON md.title_id = comp.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
