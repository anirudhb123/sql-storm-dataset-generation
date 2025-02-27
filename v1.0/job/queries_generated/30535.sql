WITH RecursiveMovieCTE AS (
    SELECT 
        m.id AS movie_id, 
        t.title, 
        t.production_year, 
        t.kind_id,
        1 AS depth
    FROM 
        aka_title t
    INNER JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year > 2000 AND 
        mc.note IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id, 
        t.title, 
        t.production_year, 
        t.kind_id,
        depth + 1
    FROM 
        RecursiveMovieCTE m
    INNER JOIN 
        movie_link ml ON m.movie_id = ml.movie_id
    INNER JOIN 
        aka_title t ON ml.linked_movie_id = t.id
    WHERE 
        m.depth < 3
),
DistinctKeywords AS (
    SELECT DISTINCT 
        mk.keyword_id,
        k.keyword
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
),
RoleCount AS (
    SELECT 
        c.movie_id,
        COUNT(CASE WHEN r.role = 'lead' THEN 1 END) AS lead_roles,
        COUNT(CASE WHEN r.role = 'support' THEN 1 END) AS support_roles
    FROM 
        cast_info c
    INNER JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    r.movie_id,
    m.title,
    m.production_year,
    r.lead_roles,
    r.support_roles,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    CASE
        WHEN m.production_year < 2010 THEN 'Before 2010'
        ELSE 'After 2009'
    END AS production_period,
    COALESCE(NULLIF(c.name, ''), 'Unknown') AS company_name,
    ROW_NUMBER() OVER (PARTITION BY m.kind_id ORDER BY m.production_year DESC) AS rank_within_kind
FROM 
    RecursiveMovieCTE m
LEFT JOIN 
    RoleCount r ON m.movie_id = r.movie_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
GROUP BY 
    r.movie_id, m.title, m.production_year, r.lead_roles, r.support_roles, c.name
HAVING 
    COUNT(mk.keyword_id) > 5
ORDER BY 
    production_period, rank_within_kind;
