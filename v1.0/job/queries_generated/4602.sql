WITH MovieCounts AS (
    SELECT 
        ct.id AS company_type_id,
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        ct.id
),
TopCompanies AS (
    SELECT 
        cn.name, 
        COALESCE(mc.movie_count, 0) AS movie_count 
    FROM 
        company_name cn
    LEFT JOIN 
        MovieCounts mc ON cn.id = (SELECT company_id FROM movie_companies WHERE movie_companies.id = cn.id)
    WHERE 
        cn.country_code IS NOT NULL
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
TitleInfo AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count 
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    tc.name AS company_name,
    ti.title AS movie_title,
    ti.production_year,
    ti.cast_count AS number_of_cast,
    ROW_NUMBER() OVER (PARTITION BY tc.name ORDER BY ti.production_year DESC) AS rank_within_company
FROM 
    TopCompanies tc
JOIN 
    movie_companies mc ON tc.name = (SELECT name FROM company_name WHERE id = mc.company_id)
JOIN 
    TitleInfo ti ON mc.movie_id = ti.movie_title
WHERE 
    ti.cast_count > 5
ORDER BY 
    tc.movie_count DESC, ti.production_year ASC;
