WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

EmployeeRoles AS (
    SELECT 
        CAST(c.role_id AS INTEGER) AS role_id, 
        COUNT(c.person_id) AS role_count
    FROM 
        cast_info c
    GROUP BY 
        c.role_id
),

CombinedInfo AS (
    SELECT 
        c.person_id, 
        STRING_AGG(DISTINCT a.name, ', ') AS aka_names, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        MIN(ri.year_rank) AS earliest_rank
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON c.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        RankedTitles ri ON c.movie_id = ri.title_id
    GROUP BY 
        c.person_id
),

FinalResult AS (
    SELECT 
        p.id AS person_id,
        p.name,
        COALESCE(ci.aka_names, 'No Aliases') AS aliases,
        COALESCE(ci.keywords, 'No Keywords') AS keyword_list,
        COALESCE(role_count, 0) AS total_roles
    FROM 
        name p
    LEFT JOIN 
        CombinedInfo ci ON p.id = ci.person_id
    LEFT JOIN 
        (SELECT 
            person_id, 
            SUM(role_count) AS role_count 
         FROM 
            EmployeeRoles er 
         INNER JOIN 
            cast_info c ON er.role_id = c.role_id 
         GROUP BY person_id) role_summary ON p.id = role_summary.person_id
)

SELECT 
    fr.person_id,
    fr.name,
    fr.aliases,
    fr.keyword_list,
    fr.total_roles,
    CASE 
        WHEN fr.total_roles > 10 THEN 'Experienced'
        WHEN fr.total_roles BETWEEN 1 AND 10 THEN 'Novice'
        ELSE 'Unknown'
    END AS experience_level,
    CASE 
        WHEN fr.aliases IS NULL THEN 'No Alias Provided'
        ELSE 'Aliases Available'
    END AS alias_status
FROM 
    FinalResult fr
WHERE 
    fr.name LIKE '%John%'
    OR fr.keyword_list LIKE '%Thriller%'
ORDER BY 
    fr.total_roles DESC NULLS LAST;
