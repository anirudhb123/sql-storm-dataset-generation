
WITH TitleDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
CastDetails AS (
    SELECT 
        c.movie_id,
        ARRAY_AGG(DISTINCT CONCAT(a.name, ' as ', r.role)) AS cast_list
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT CONCAT(cn.name, ' (', ct.kind, ')')) AS companies
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
    td.title,
    td.production_year,
    td.keywords,
    cd.cast_list,
    COALESCE(cd.cast_list, ARRAY_CONSTRUCT('No Cast')) AS cast_list,
    COALESCE(cod.companies, ARRAY_CONSTRUCT('No Companies')) AS companies
FROM 
    TitleDetails td
LEFT JOIN 
    CastDetails cd ON td.title_id = cd.movie_id
LEFT JOIN 
    CompanyDetails cod ON td.title_id = cod.movie_id
WHERE 
    td.production_year >= 2000
ORDER BY 
    td.production_year DESC, 
    td.title;
