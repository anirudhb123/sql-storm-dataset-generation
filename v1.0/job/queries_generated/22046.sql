WITH RankedTitles AS (
    SELECT 
        a.person_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn,
        COUNT(t.id) OVER (PARTITION BY a.person_id) AS total_titles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL 
        AND t.production_year > 2000
),
FilteredTitles AS (
    SELECT 
        rt.person_id,
        rt.title,
        rt.production_year,
        rt.total_titles,
        CASE 
            WHEN rt.rn = 1 THEN 'Latest Title'
            ELSE 'Previous Title'
        END AS title_status
    FROM 
        RankedTitles rt
    WHERE 
        rt.rn <= 3
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
CompanyRoles AS (
    SELECT 
        mc.movie_id,
        c.kind AS company_type,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_type c ON mc.company_type_id = c.id
    GROUP BY 
        mc.movie_id, c.kind
)
SELECT 
    ft.person_id,
    ft.title,
    ft.production_year,
    ft.total_titles,
    ft.title_status,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    cr.company_type,
    cr.company_count,
    CASE 
        WHEN cr.company_count IS NULL THEN 'No companies involved'
        WHEN cr.company_count = 0 THEN 'Companies involved but count is 0'
        ELSE 'Companies involved'
    END AS company_status
FROM 
    FilteredTitles ft
LEFT JOIN 
    MovieKeywords mk ON ft.person_id = mk.movie_id 
    LEFT JOIN Movie_companies mc ON ft.person_id = mc.movie_id
LEFT JOIN 
    CompanyRoles cr ON mc.movie_id = cr.movie_id
WHERE 
    (cr.company_count IS NOT NULL OR ft.production_year < 2015)
    AND NOT EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = ft.movie_id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
        AND mi.info IS NULL
    )
ORDER BY 
    ft.person_id, ft.production_year DESC;
