WITH movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_companies_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS company_names,
        STRING_AGG(ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
full_movie_info AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(mk.keyword_list, '') AS keywords,
        COALESCE(mci.company_names, '') AS companies,
        COALESCE(mci.company_types, '') AS company_types
    FROM 
        title t
    LEFT JOIN 
        movie_keywords mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_companies_info mci ON t.id = mci.movie_id
)
SELECT
    fmi.title,
    fmi.production_year,
    fmi.keywords,
    fmi.companies,
    fmi.company_types,
    CONCAT('Title: ', fmi.title, ' | Year: ', fmi.production_year, 
           ' | Keywords: ', fmi.keywords, 
           ' | Companies: ', fmi.companies, 
           ' | Company Types: ', fmi.company_types) AS formatted_output
FROM 
    full_movie_info fmi
WHERE 
    fmi.production_year BETWEEN 2000 AND 2020
ORDER BY 
    fmi.production_year DESC;
