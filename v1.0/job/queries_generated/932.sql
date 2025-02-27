WITH MovieRoles AS (
    SELECT 
        at.title, 
        at.production_year, 
        ca.person_id, 
        ca.role_id,
        rn.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ca.nr_order) AS role_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ca ON at.id = ca.movie_id
    JOIN 
        role_type rn ON ca.role_id = rn.id
),
CompanyCounts AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
KeywordSummary AS (
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
    m.title, 
    m.production_year, 
    mr.person_id, 
    mr.role_name,
    COALESCE(cc.company_count, 0) AS total_companies,
    COALESCE(ks.keywords, 'No keywords') AS keywords
FROM 
    MovieRoles mr
JOIN 
    aka_title m ON mr.title = m.title AND mr.production_year = m.production_year
LEFT JOIN 
    CompanyCounts cc ON m.id = cc.movie_id
LEFT JOIN 
    KeywordSummary ks ON m.id = ks.movie_id
WHERE 
    mr.role_rank <= 3
ORDER BY 
    m.production_year DESC, 
    m.title ASC;
