WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        CAST(NULL AS text) AS parent_title,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        e.kind_id,
        p.title AS parent_title,
        depth + 1
    FROM 
        aka_title e
    JOIN 
        aka_title p ON e.episode_of_id = p.id
    WHERE 
        e.episode_of_id IS NOT NULL
),
CastInfo AS (
    SELECT 
        c.person_id,
        c.movie_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
), 
Keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id 
    GROUP BY 
        mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.parent_title,
    COUNT(DISTINCT c.person_id) AS total_actors,
    SUM(CASE WHEN ci.role_order = 1 THEN 1 ELSE 0 END) AS lead_roles,
    k.keywords,
    COALESCE(mc.companies, 'None') AS companies_involved,
    COALESCE(mc.company_count, 0) AS total_company_count,
    ROW_NUMBER() OVER (PARTITION BY mh.kind_id ORDER BY mh.production_year DESC) AS kind_ranking
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastInfo c ON mh.movie_id = c.movie_id
LEFT JOIN 
    Keywords k ON mh.movie_id = k.movie_id
LEFT JOIN 
    MovieCompanies mc ON mh.movie_id = mc.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.parent_title, k.keywords, mc.companies, mc.company_count
HAVING 
    COUNT(DISTINCT c.person_id) > 5
ORDER BY 
    mh.production_year DESC, total_actors DESC, kind_ranking;
