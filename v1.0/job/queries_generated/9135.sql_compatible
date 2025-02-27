
WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT CONCAT(a.name, ' as ', rt.role), ', ') AS cast_list
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    GROUP BY 
        c.movie_id
)
SELECT 
    md.title_id,
    md.title,
    md.production_year,
    md.kind_id,
    md.keywords,
    cd.cast_list,
    md.companies
FROM 
    MovieDetails md
LEFT JOIN 
    CastDetails cd ON md.title_id = cd.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.title;
