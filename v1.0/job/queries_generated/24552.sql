WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyTitles AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FilteredMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
        COALESCE(c.company_name, 'Unknown Company') AS production_company
    FROM 
        title t
    LEFT JOIN 
        MovieKeywords mk ON t.id = mk.movie_id
    LEFT JOIN 
        CompanyTitles c ON t.id = c.movie_id AND c.company_rank = 1
)
SELECT 
    ft.movie_id,
    ft.title,
    ft.production_year,
    ft.movie_keywords,
    COUNT(ci.id) AS cast_count,
    MAX(rt.aka_name) AS recent_aka_name
FROM 
    FilteredMovies ft
LEFT JOIN 
    cast_info ci ON ft.movie_id = ci.movie_id
LEFT JOIN 
    RankedTitles rt ON ci.person_id = rt.aka_id AND rt.rn = 1
GROUP BY 
    ft.movie_id, ft.title, ft.production_year, ft.movie_keywords
HAVING 
    COUNT(ci.id) > 5 
    AND ft.production_year > (SELECT EXTRACT(YEAR FROM CURRENT_DATE) - 20)
ORDER BY 
    ft.production_year DESC, ft.movie_id
LIMIT 50 OFFSET 10;

This SQL query retrieves and ranks movies while considering various factors such as the associated actors, company production details, and keywords. It uses common table expressions (CTEs) to rank titles and gather keywords, along with outer joins for flexibility and handling of NULLs in the data. The final output is filtered based on the number of cast members and the production year, showcasing advanced SQL features including string aggregation, window functions, and unexpected NULL logic handling.
