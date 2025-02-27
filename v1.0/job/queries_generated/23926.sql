WITH RecursiveTitleCTE AS (
    SELECT 
        t.id, 
        t.title, 
        t.production_year, 
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        nt.id,
        nt.title,
        nt.production_year,
        rt.level + 1
    FROM 
        aka_title nt
    JOIN 
        RecursiveTitleCTE rt ON nt.episode_of_id = rt.id
), TitleRankCTE AS (
    SELECT 
        title,
        production_year,
        RANK() OVER (PARTITION BY production_year ORDER BY title) AS title_rank
    FROM 
        RecursiveTitleCTE
), TitleWithKeywords AS (
    SELECT 
        tt.title,
        tk.keyword
    FROM 
        TitleRankCTE tt
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = tt.id
    LEFT JOIN 
        keyword tk ON mk.keyword_id = tk.id
    WHERE 
        tt.title_rank <= 5
), TitleCompanyCTE AS (
    SELECT 
        t.title,
        c.name AS company_name,
        STRING_AGG(ct.kind, ', ') AS company_types
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        t.title, c.name
), CombinedResults AS (
    SELECT 
        twk.title,
        twk.keyword,
        tc.company_name,
        tc.company_types
    FROM 
        TitleWithKeywords twk
    FULL OUTER JOIN 
        TitleCompanyCTE tc ON twk.title = tc.title
)
SELECT 
    cr.title,
    COALESCE(cr.keyword, 'No Keywords') AS keyword,
    COALESCE(cr.company_name, 'No Company') AS company_name,
    COALESCE(cr.company_types, 'No Types') AS company_types,
    CASE 
        WHEN cr.company_name IS NOT NULL THEN 'Produced by ' || cr.company_name 
        ELSE 'Independent Production'
    END AS production_status,
    CASE 
        WHEN cr.keyword IS NOT NULL THEN 'Keyword present'
        ELSE 'Keyword absent'
    END AS keyword_status
FROM 
    CombinedResults cr
ORDER BY 
    cr.title ASC,
    cr.keyword DESC NULLS LAST;
