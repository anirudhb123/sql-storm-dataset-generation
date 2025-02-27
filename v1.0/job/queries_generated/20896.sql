WITH RankedTitles AS (
    SELECT 
        a.person_id,
        a.name,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
        AND t.production_year IS NOT NULL
),
FilteredRankedTitles AS (
    SELECT 
        person_id,
        name,
        title,
        production_year
    FROM 
        RankedTitles
    WHERE 
        rn <= 5
),
CompanyData AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        row_number() OVER (PARTITION BY mc.movie_id ORDER BY c.name ASC) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
ComplexJoin AS (
    SELECT 
        f.person_id,
        f.name,
        f.title,
        f.production_year,
        cd.company_name,
        cd.company_type
    FROM 
        FilteredRankedTitles f
    LEFT JOIN 
        complete_cast cc ON f.title = cc.movie_id
    LEFT JOIN 
        CompanyData cd ON cc.movie_id = cd.movie_id AND cd.company_rank = 1
)
SELECT 
    coalesce(cast_info.id, 9999999) AS cast_info_id,
    p.name AS person_name,
    COALESCE(f.title, 'Unknown Title') AS movie_title,
    COALESCE(f.production_year, 1900) AS year_of_release,
    CASE 
        WHEN cd.company_name IS NULL THEN 'No Company Info'
        ELSE cd.company_name
    END AS production_company,
    CASE
        WHEN cd.company_type IS NULL THEN 'N/A'
        ELSE cd.company_type
    END AS company_type
FROM 
    cast_info
LEFT JOIN 
    ComplexJoin f ON cast_info.movie_id = f.title AND cast_info.person_id = f.person_id
LEFT JOIN 
    aka_name p ON cast_info.person_id = p.person_id
WHERE 
    cast_info.note IS NULL
    AND (f.production_year IS NULL OR f.production_year > 2000)
ORDER BY 
    p.name, year_of_release DESC;
