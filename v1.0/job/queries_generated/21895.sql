WITH RecursiveActorCTE AS (
    SELECT 
        ak.name AS actor_name,
        ct.kind AS character_type,
        ti.title AS movie_title,
        ti.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY ti.production_year DESC) AS recent_movie_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title ti ON ci.movie_id = ti.movie_id
    JOIN 
        comp_cast_type ct ON ci.role_id = ct.id
    WHERE 
        ct.kind IS NOT NULL
),

DistinctKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
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
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ' ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.name IS NOT NULL
    GROUP BY 
        mc.movie_id
)

SELECT 
    actor_cte.actor_name,
    actor_cte.movie_title,
    actor_cte.production_year,
    dk.keywords_list,
    mc.company_count,
    mc.company_names
FROM 
    RecursiveActorCTE actor_cte
LEFT JOIN 
    DistinctKeywords dk ON actor_cte.recent_movie_rank = 1 AND actor_cte.movie_title = dk.movie_title
LEFT JOIN 
    MovieCompanies mc ON actor_cte.movie_title = mc.movie_id
WHERE 
    actor_cte.recent_movie_rank ≤ 3
ORDER BY 
    actor_cte.actor_name, actor_cte.production_year DESC;

-- Additional complexity focusing on NULL logic and string conditions
WITH ComplexPredicate AS (
    SELECT 
        ak.id,
        ak.name,
        ak.name_pcode_cf,
        COALESCE(NULLIF(ak.md5sum, ''), 'No MD5 Provided') AS md5_status,
        CASE 
            WHEN ak.name IS NULL THEN 'Unknown Name'
            WHEN ak.name LIKE '%Bruce%' THEN 'Famous Actor'
            ELSE 'Regular Actor'
        END AS actor_classification
    FROM 
        aka_name ak
    WHERE 
        ak.name IS NOT NULL
        OR ak.md5sum IS NOT NULL
)

SELECT 
    cp.name,
    cp.md5_status,
    cp.actor_classification
FROM 
    ComplexPredicate cp
WHERE 
    cp.actor_classification = 'Famous Actor'
ORDER BY 
    cp.name;
