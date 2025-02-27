WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.person_id,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        aka_title t ON a.id = t.id
    WHERE 
        a.name IS NOT NULL AND 
        t.production_year IS NOT NULL
),
FilteredRoles AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        c.person_id,
        c.person_role_id,
        c.nr_order,
        ROLE.role AS person_role,
        CASE 
            WHEN c.note IS NULL THEN 'No note provided'
            ELSE c.note
        END AS role_note
    FROM 
        cast_info c
    JOIN 
        role_type ROLE ON c.role_id = ROLE.id
    WHERE 
        c.nr_order <= 5
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        movie_keyword k ON m.movie_id = k.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
)
SELECT 
    rt.aka_id,
    rt.title,
    rt.production_year,
    fr.person_role,
    fr.role_note,
    md.movie_id,
    md.title AS movie_title,
    md.company_count,
    md.keywords,
    CASE 
        WHEN md.company_count = 0 THEN 'No companies associated'
        ELSE 'Companies available'
    END AS company_status,
    COALESCE((
        SELECT 
            COUNT(DISTINCT m.id) 
        FROM 
            title m 
        WHERE 
            m.production_year = rt.production_year AND 
            m.id <> rt.title_id
    ), 0) AS same_year_count
FROM 
    RankedTitles rt
LEFT JOIN 
    FilteredRoles fr ON rt.person_id = fr.person_id
LEFT JOIN 
    MovieDetails md ON rt.title_id = md.movie_id
WHERE 
    rt.rn = 1
ORDER BY 
    rt.production_year DESC, 
    md.company_count DESC NULLS LAST, 
    rt.title;

This SQL query utilizes Common Table Expressions (CTEs) to structure the data effectively, employing window functions to rank titles, correlated subqueries for year comparisons, string aggregation for keywords, and comprehensive use of outer joins to pull in relevant relationships while also managing null logic for clarity in case of missing data. The use of `STRING_AGG` and `COALESCE` introduces complexities and provides a rich dataset for performance benchmarking.
