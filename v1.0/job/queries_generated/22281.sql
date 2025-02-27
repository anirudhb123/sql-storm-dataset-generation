WITH RecursiveActorRoles AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        rk.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY ca.nr_order) AS role_rank
    FROM 
        cast_info ca
    JOIN 
        role_type rk ON ca.role_id = rk.id
), 
CompanyMovieStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS distinct_companies,
        MAX(CASE WHEN c.kind = 'Production' THEN mc.note END) AS production_note,
        SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_type c ON mc.company_type_id = c.id
    GROUP BY 
        mc.movie_id
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
)
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    COALESCE(r.actor_role, 'No Role Assigned') AS assigned_role,
    cs.distinct_companies,
    cs.production_note,
    ks.keywords,
    CASE 
        WHEN cs.company_count > 5 THEN 'Many Companies'
        WHEN cs.company_count < 1 THEN 'No Companies'
        ELSE 'Few Companies'
    END AS company_summary,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = t.id AND cc.status_id IS NOT NULL) AS total_complete_cast,
    (SELECT AVG(length(i.info)) 
     FROM movie_info i 
     WHERE i.movie_id = t.id AND i.note IS NOT NULL) AS avg_info_length
FROM 
    title t
LEFT JOIN 
    aka_title ak ON t.id = ak.movie_id
LEFT JOIN 
    RecursiveActorRoles r ON ak.id = r.movie_id
LEFT JOIN 
    aka_name a ON r.person_id = a.person_id
LEFT JOIN 
    CompanyMovieStats cs ON t.id = cs.movie_id
LEFT JOIN 
    MovieKeywords ks ON t.id = ks.movie_id
WHERE 
    (t.production_year BETWEEN 2000 AND 2023 OR t.production_year IS NULL) 
    AND (a.name IS NOT NULL OR r.actor_role IS NULL)
ORDER BY 
    t.production_year DESC,
    company_summary DESC,
    actor_name
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
