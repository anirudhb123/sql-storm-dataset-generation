WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER(PARTITION BY a.id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        rt.role,
        ROW_NUMBER() OVER(PARTITION BY ci.person_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
AggregateContributors AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    t.title,
    COALESCE(t.production_year, 'Unknown') AS production_year,
    ar.person_id,
    ar.role,
    ac.company_count,
    ac.company_names,
    CASE 
        WHEN ar.role IS NULL THEN 'Undefined Role'
        ELSE ar.role
    END AS role_description,
    ROW_NUMBER() OVER (PARTITION BY t.title ORDER BY ac.company_count DESC) AS title_rank
FROM 
    RankedTitles t
LEFT JOIN 
    ActorRoles ar ON t.id = ar.movie_id
LEFT JOIN 
    AggregateContributors ac ON t.id = ac.movie_id
WHERE 
    (t.keyword IS NOT NULL AND t.rn = 1)
    OR (ac.company_count > 5 AND ac.company_names IS NOT NULL)
    OR (t.production_year IS NULL AND ar.person_id IS NOT NULL)
ORDER BY 
    title_rank,
    COALESCE(ac.company_count, 0) DESC;
