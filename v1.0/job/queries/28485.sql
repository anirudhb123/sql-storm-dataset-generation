WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        A.NAME AS main_actor,
        string_agg(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name A ON A.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year >= 2000 
        AND A.name IS NOT NULL 
    GROUP BY 
        t.id, t.title, t.production_year, A.NAME
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        string_agg(DISTINCT cn.name, ', ') AS production_companies,
        string_agg(DISTINCT ct.kind, ', ') AS company_types
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
    MD.movie_id,
    MD.title,
    MD.production_year,
    MD.main_actor,
    COALESCE(CD.production_companies, 'N/A') AS production_companies,
    COALESCE(CD.company_types, 'N/A') AS company_types,
    MD.keywords
FROM 
    MovieDetails MD
LEFT JOIN 
    CompanyDetails CD ON MD.movie_id = CD.movie_id
ORDER BY 
    MD.production_year DESC, 
    MD.title;
