
WITH Recursive_CTE AS (
    
    SELECT 
        title.id AS movie_id,
        title.title,
        AVG(aka_title.production_year) AS avg_year,
        MIN(aka_title.production_year) AS min_year,
        MAX(aka_title.production_year) AS max_year,
        ROW_NUMBER() OVER (ORDER BY title.production_year DESC) AS rn
    FROM 
        title
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    WHERE 
        aka_title.production_year IS NOT NULL
    GROUP BY 
        title.id, title.title
),
Company_Info AS (
    
    SELECT 
        movie_id,
        LISTAGG(DISTINCT company_name.name, ', ') WITHIN GROUP (ORDER BY company_name.name) AS company_names,
        LISTAGG(DISTINCT company_type.kind, ', ') WITHIN GROUP (ORDER BY company_type.kind) AS company_types
    FROM 
        movie_companies
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    JOIN 
        company_type ON movie_companies.company_type_id = company_type.id
    GROUP BY 
        movie_id
),
Role_Count AS (
    
    SELECT 
        movie_id,
        COUNT(DISTINCT role_id) AS role_count
    FROM 
        cast_info
    GROUP BY 
        movie_id
),
Final_Benchmark AS (
    
    SELECT 
        rec.movie_id,
        rec.title,
        rec.avg_year,
        rec.min_year,
        rec.max_year,
        COALESCE(ci.company_names, 'No companies') AS companies,
        COALESCE(ci.company_types, 'No types') AS types,
        COALESCE(rc.role_count, 0) AS role_count
    FROM 
        Recursive_CTE rec
    LEFT JOIN 
        Company_Info ci ON rec.movie_id = ci.movie_id
    LEFT JOIN 
        Role_Count rc ON rec.movie_id = rc.movie_id
)

SELECT 
    *,
    CASE 
        WHEN avg_year IS NULL THEN 'No data'
        WHEN avg_year < 2000 THEN 'Pre-millennium'
        WHEN avg_year BETWEEN 2000 AND 2010 THEN 'Millennium decade'
        ELSE 'Post millennium'
    END AS year_category
FROM 
    Final_Benchmark
WHERE 
    (role_count > 0 OR companies IS NOT NULL)
    AND (avg_year IS NOT NULL OR companies IS NOT NULL)
ORDER BY 
    role_count DESC, avg_year DESC;
