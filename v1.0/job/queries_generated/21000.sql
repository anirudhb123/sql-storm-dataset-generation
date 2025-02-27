WITH RecursiveTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t 
    WHERE 
        t.production_year IS NOT NULL
),
CTE_Cast AS (
    SELECT 
        c.movie_id, 
        p.name AS person_name,
        ct.kind AS role_kind,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS cast_order
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        comp_cast_type ct ON c.role_id = ct.id
),
MovieGenres AS (
    SELECT 
        t.id AS title_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        aka_title t 
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id 
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    GROUP BY 
        t.id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS companies_list
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    m.companies_list,
    m.company_count,
    g.genres,
    CAST(
        CASE 
            WHEN m.company_count = 0 THEN 'Unknown' 
            ELSE 'Known' 
        END AS VARCHAR(10)
    ) AS company_status,
    STRING_AGG(DISTINCT c.person_name || ' as ' || c.role_kind, '; ') AS cast_details
FROM 
    RecursiveTitles rt
LEFT JOIN 
    MovieCompanies m ON rt.title_id = m.movie_id
LEFT JOIN 
    MovieGenres g ON rt.title_id = g.title_id
LEFT JOIN 
    CTE_Cast c ON rt.title_id = c.movie_id AND c.cast_order <= 3
WHERE 
    rt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
    AND rt.production_year BETWEEN 2000 AND 2023
GROUP BY 
    rt.title, rt.production_year, m.companies_list, m.company_count, g.genres
ORDER BY 
    rt.production_year DESC, rt.title;
