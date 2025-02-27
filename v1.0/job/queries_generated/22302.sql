WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rn
    FROM aka_title a
    WHERE a.production_year IS NOT NULL
),
company_movie_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        MAX(CASE WHEN cty.kind = 'Distributor' THEN cn.name END) AS distributor,
        MAX(CASE WHEN cty.kind = 'Production' THEN cn.name END) AS production_company
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type cty ON mc.company_type_id = cty.id
    GROUP BY mc.movie_id
),
person_roles AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    cmi.companies,
    cmi.distributor,
    cmi.production_company,
    pr.actors,
    pr.roles
FROM ranked_movies rm
LEFT JOIN company_movie_info cmi ON rm.movie_id = cmi.movie_id
LEFT JOIN person_roles pr ON rm.movie_id = pr.movie_id
WHERE rm.rn = 1
AND (cmi.distributor IS NOT NULL OR cmi.production_company IS NOT NULL)
ORDER BY rm.production_year DESC, rm.movie_title;
