
WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        t.id
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
DistinctCompanies AS (
    SELECT 
        DISTINCT cn.name, 
        ct.kind
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL
),
MovieGenres AS (
    SELECT 
        m.id AS movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.id
)
SELECT 
    t.title,
    t.production_year,
    d.name AS company_name,
    d.kind AS company_type,
    CASE 
        WHEN t.production_year = (SELECT MAX(production_year) FROM aka_title) 
        THEN 'Latest Year' 
        ELSE 'Earlier Year' 
    END AS year_label,
    COALESCE(mg.keywords, 'No Keywords') AS movie_keywords
FROM 
    RankedTitles t
LEFT JOIN 
    DistinctCompanies d ON d.kind IN ('Production', 'Distributor')
LEFT JOIN 
    MovieGenres mg ON t.id = mg.movie_id
WHERE 
    t.year_rank <= 5
GROUP BY 
    t.title, t.production_year, d.name, d.kind, t.id, mg.keywords
ORDER BY 
    t.production_year DESC, t.title;
