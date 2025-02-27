WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        c.kind AS company_kind,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title AS t
        JOIN movie_companies AS mc ON t.id = mc.movie_id
        JOIN company_type AS c ON mc.company_type_id = c.id
        LEFT JOIN cast_info AS ci ON t.id = ci.movie_id
        LEFT JOIN aka_name AS ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
        AND c.kind IS NOT NULL
    GROUP BY 
        t.title, t.production_year, c.kind
),
TopCompanies AS (
    SELECT 
        company_name.name,
        COUNT(*) AS movie_count
    FROM 
        movie_companies AS mc
        JOIN company_name ON mc.company_id = company_name.id
    GROUP BY 
        company_name.name
    HAVING 
        COUNT(*) > 10
)
SELECT 
    md.title,
    md.production_year,
    md.company_kind,
    md.actor_names,
    COALESCE(tc.movie_count, 0) AS total_movies_by_company
FROM 
    MovieDetails AS md
LEFT JOIN 
    TopCompanies AS tc ON md.company_kind = tc.name
ORDER BY 
    md.production_year DESC, 
    md.title;