WITH RecursiveTitleCTE AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.produced_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredCompanyName AS (
    SELECT 
        c.id AS company_id,
        c.name,
        CASE 
            WHEN c.country_code IS NULL THEN 'Unknown Country'
            ELSE c.country_code
        END AS country
    FROM 
        company_name c
    WHERE 
        c.name ILIKE '%Production%' OR c.name ILIKE '%Films%'
),
MovieDirectorRoles AS (
    SELECT 
        ci.movie_id,
        p.name AS director_name,
        ct.kind,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order ASC) AS director_rank
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        rt.role ILIKE '%director%'
)
SELECT 
    tt.title AS Movie_Title,
    tt.production_year AS Release_Year,
    cn.name AS Production_Company,
    d.director_name AS Director,
    CASE 
        WHEN d.director_rank = 1 THEN 'Primary Director'
        WHEN d.director_rank IS NULL THEN 'No Director Listed'
        ELSE 'Secondary Director'
    END AS Director_Type,
    COUNT(DISTINCT mk.keyword) AS Keyword_Count
FROM 
    RecursiveTitleCTE tt
LEFT JOIN 
    movie_info m ON tt.title_id = m.movie_id
LEFT JOIN 
    MovieDirectorRoles d ON tt.title_id = d.movie_id
LEFT JOIN 
    movie_keyword mk ON tt.title_id = mk.movie_id
LEFT JOIN 
    FilteredCompanyName cn ON m.info_type_id = cn.company_id
WHERE 
    tt.title_rank = 1 
    AND (m.info IS NOT NULL OR mk.keyword IS NOT NULL) 
    AND NOT EXISTS (
        SELECT 1 
        FROM movie_link ml 
        WHERE ml.movie_id = tt.title_id 
          AND ml.link_type_id IS NULL
    )
GROUP BY 
    tt.title, tt.production_year, cn.name, d.director_name, d.director_rank
ORDER BY 
    tt.production_year DESC, COUNT(DISTINCT mk.keyword) DESC;
