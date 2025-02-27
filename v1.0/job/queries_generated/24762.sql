WITH RecursiveCTE AS (
    SELECT 
        a.id AS aka_id,
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
        a.name IS NOT NULL AND 
        a.name <> ''
),
TitleWithDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(m.nm_pcode_nf, 'N/A') AS nm_pcode_nf
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre' LIMIT 1)
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
),
CastRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.role_id) AS role_count,
        MAX(CASE WHEN r.role = 'Lead' THEN 1 ELSE 0 END) AS has_lead_role
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    r.aka_id,
    r.name,
    td.title,
    td.production_year,
    CASE 
        WHEN cr.role_count > 5 THEN 'Ensemble'
        WHEN cr.has_lead_role = 1 THEN 'Lead'
        ELSE 'Supporting' 
    END AS cast_type,
    r.production_year - td.production_year AS year_difference,
    STRING_AGG(DISTINCT tn.name, ', ') FILTER (WHERE tn.name IS NOT NULL) AS co_stars
FROM 
    RecursiveCTE r
JOIN 
    TitleWithDetails td ON r.title = td.title AND r.production_year = td.production_year
LEFT JOIN 
    cast_info ci ON ci.movie_id = td.title_id
LEFT JOIN 
    aka_name tn ON tn.person_id = ci.person_id AND tn.md5sum IS NOT NULL
LEFT JOIN 
    CastRoles cr ON cr.movie_id = td.title_id
WHERE 
    r.rn = 1
GROUP BY 
    r.aka_id, r.name, td.title, td.production_year, cr.role_count, cr.has_lead_role
HAVING 
    COUNT(DISTINCT tn.name) > 0 AND 
    (year_difference = (SELECT MAX(year_difference) FROM (SELECT r.production_year - td.production_year AS year_difference) AS sub) 
     OR year_difference IS NULL)
ORDER BY 
    r.name ASC, td.production_year DESC;
