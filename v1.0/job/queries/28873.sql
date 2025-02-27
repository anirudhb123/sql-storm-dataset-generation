WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actors_list
    FROM 
        aka_title t
        JOIN cast_info ci ON t.id = ci.movie_id
        JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
        JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.actors_list,
    mk.keywords,
    cd.companies,
    cd.company_types
FROM 
    MovieDetails md
    LEFT JOIN MovieKeywords mk ON md.movie_id = mk.movie_id
    LEFT JOIN CompanyDetails cd ON md.movie_id = cd.movie_id
WHERE 
    md.production_year >= 2000 
ORDER BY 
    md.production_year DESC, 
    md.title;