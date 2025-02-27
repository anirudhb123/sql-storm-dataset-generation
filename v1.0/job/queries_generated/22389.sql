WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mv.linked_movie_id, 
        t.title, 
        t.production_year, 
        mh.level + 1
    FROM 
        movie_link mv
    JOIN 
        title t ON mv.linked_movie_id = t.id
    JOIN 
        movie_hierarchy mh ON mv.movie_id = mh.movie_id
),

-- Get distinct actor names with their roles and movie titles
actor_roles AS (
    SELECT 
        ak.name AS actor_name,
        ac.role_id,
        at.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY at.production_year DESC) AS role_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ac ON ak.person_id = ac.person_id
    JOIN 
        aka_title at ON ac.movie_id = at.movie_id
    JOIN 
        movie_companies mc ON ac.movie_id = mc.movie_id
    JOIN 
        movie_info mi ON ac.movie_id = mi.movie_id
    LEFT JOIN 
        movie_hierarchy mh ON ac.movie_id = mh.movie_id
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
        AND (at.production_year IS NOT NULL OR mh.movie_id IS NOT NULL)
),

-- CTE to calculate aggregate roles per actor
role_summary AS (
    SELECT 
        actor_name, 
        COUNT(DISTINCT role_id) AS total_roles,
        COUNT(DISTINCT title) OVER (PARTITION BY actor_name) AS movie_count,
        MAX(production_year) AS last_movie_year
    FROM 
        actor_roles
    WHERE 
        at.production_year > 2000
    GROUP BY 
        actor_name
)

-- Final query to catalogue results with unusual semantics
SELECT 
    r.actor_name,
    r.total_roles,
    r.movie_count,
    COALESCE(r.last_movie_year, 'Unknown') AS last_movie_year,
    CASE
        WHEN r.total_roles > 10 THEN 'Veteran Actor'
        WHEN r.total_roles BETWEEN 5 AND 10 THEN 'Emerging Talent'
        ELSE 'Newcomer'
    END AS actor_classification
FROM 
    role_summary r
WHERE 
    r.movie_count IS NOT NULL
ORDER BY 
    r.actor_name ASC
FETCH FIRST 20 ROWS ONLY;

-- Include an outer join to fetch companies associated with any movies, even if missing
LEFT JOIN (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
) companies ON role_summary.movie_id = companies.movie_id;
