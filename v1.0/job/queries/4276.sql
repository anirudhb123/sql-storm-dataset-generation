WITH MovieSummary AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        AVG(CASE 
            WHEN r.role = 'lead' THEN 1 
            ELSE 0 
        END) AS lead_percentage,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.id
    LEFT JOIN 
        role_type r ON ca.role_id = r.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title, t.production_year
), 
CompanyParticipation AS (
    SELECT 
        t.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id
)
SELECT 
    ms.movie_title,
    ms.production_year,
    ms.total_cast,
    ms.lead_percentage * 100 AS lead_role_percentage,
    COALESCE(cp.total_companies, 0) AS company_participation,
    CASE 
        WHEN ms.production_year IS NULL THEN 'Unknown Year'
        WHEN ms.production_year < 2000 THEN 'Classic'
        ELSE 'Modern'
    END AS movie_era,
    COALESCE(ms.keywords, 'No Keywords') AS keywords
FROM 
    MovieSummary ms
LEFT JOIN 
    CompanyParticipation cp ON ms.movie_title = (SELECT title FROM aka_title WHERE id = cp.movie_id)
WHERE 
    ms.lead_percentage IS NOT NULL
ORDER BY 
    ms.production_year DESC, 
    ms.total_cast DESC;
