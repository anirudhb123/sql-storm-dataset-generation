WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        1 AS level
    FROM 
        aka_title m
        LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        l.linked_movie_id,
        l.title,
        l.production_year,
        l.kind_id,
        COALESCE(mk2.keyword, 'No Keywords') AS keyword,
        mh.level + 1
    FROM 
        movie_link l
        JOIN MovieHierarchy mh ON l.movie_id = mh.movie_id
        LEFT JOIN aka_title m ON l.linked_movie_id = m.id
        LEFT JOIN movie_keyword mk2 ON l.linked_movie_id = mk2.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COUNT(DISTINCT mci.company_id) AS company_count,
    STRING_AGG(COALESCE(cn.name, 'Unknown Company'), ', ') AS company_names,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(mci.company_id) DESC) AS rn
FROM 
    MovieHierarchy mh
    LEFT JOIN movie_companies mci ON mh.movie_id = mci.movie_id
    LEFT JOIN company_name cn ON mci.company_id = cn.id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING 
    COUNT(mci.company_id) > 0 AND 
    mh.production_year IS NOT NULL
ORDER BY 
    mh.production_year DESC, 
    company_count DESC
LIMIT 50;

-- Additional Queries and Complex Logic
WITH ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
        JOIN aka_name ak ON ci.person_id = ak.person_id
        JOIN role_type rt ON ci.role_id = rt.id
    WHERE 
        ak.name IS NOT NULL
),
TopActors AS (
    SELECT 
        ar.movie_id,
        AR.actor_name,
        ar.role_name,
        ar.actor_rank
    FROM 
        ActorRoles ar
    WHERE 
        ar.actor_rank <= 3
)

SELECT 
    th.movie_id,
    mh.title,
    th.actor_name,
    th.role_name,
    CASE 
        WHEN th.role_name LIKE '%Lead%' THEN 'Lead Role'
        ELSE 'Supporting Role'
    END AS role_category
FROM 
    TopActors th
    JOIN aka_title mh ON th.movie_id = mh.id
WHERE 
    th.actor_name NOT LIKE '%John Doe%' AND 
    (th.role_name IS NOT NULL OR th.role_name != '')
ORDER BY 
    mh.title,
    th.actor_rank;
