
WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM aka_title a
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE a.production_year >= 2000
),
actor_roles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
),
company_details AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
movie_info_details AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_info
    FROM movie_info mi
    WHERE mi.note IS NOT NULL
    GROUP BY mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    STRING_AGG(DISTINCT ar.actor_name || ' (' || ar.role_name || ')', ', ') AS actor_roles,
    COUNT(DISTINCT cd.company_name) AS num_companies,
    STRING_AGG(DISTINCT cd.company_type, ', ') AS company_types,
    mid.movie_info
FROM ranked_movies rm
LEFT JOIN actor_roles ar ON rm.movie_id = ar.movie_id
LEFT JOIN company_details cd ON rm.movie_id = cd.movie_id
LEFT JOIN movie_info_details mid ON rm.movie_id = mid.movie_id
WHERE rm.rank = 1
GROUP BY rm.movie_id, rm.title, rm.production_year, mid.movie_info
ORDER BY rm.production_year DESC, rm.title ASC;
