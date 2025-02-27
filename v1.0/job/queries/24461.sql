WITH RECURSIVE valid_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(NULLIF(t.production_year, 0), NULL) AS valid_year
    FROM title t
    WHERE t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        NULL 
    FROM title t
    JOIN valid_movies vm ON t.id = vm.movie_id
    WHERE valid_year IS NULL 
),

cast_roles AS (
    SELECT 
        ci.movie_id,
        c.id AS actor_id,
        ra.role,
        ROW_NUMBER() OVER(PARTITION BY ci.movie_id ORDER BY c.name) AS role_rank
    FROM cast_info ci
    JOIN aka_name c ON ci.person_id = c.person_id
    JOIN role_type ra ON ci.role_id = ra.id
),

keyword_info AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),

movie_company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),

final_benchmark AS (
    SELECT 
        vm.movie_id,
        vm.title,
        vm.valid_year,
        kr.actor_id,
        kr.role,
        kr.role_rank,
        ki.keyword_list,
        ci.companies
    FROM valid_movies vm
    LEFT JOIN cast_roles kr ON vm.movie_id = kr.movie_id
    LEFT JOIN keyword_info ki ON vm.movie_id = ki.movie_id
    LEFT JOIN movie_company_info ci ON vm.movie_id = ci.movie_id
    WHERE vm.valid_year IS NOT NULL 
      AND (kr.role IS NULL OR kr.role = 'Main' OR kr.role_rank <= 3) 
)

SELECT 
    fb.movie_id,
    fb.title,
    fb.valid_year,
    COALESCE(fb.role, 'Unknown') AS role,
    COALESCE(fb.keyword_list, 'No Keywords') AS keyword_list,
    COALESCE(fb.companies, 'No Companies') AS companies
FROM final_benchmark fb
WHERE fb.valid_year >= (SELECT AVG(valid_year) FROM final_benchmark)
ORDER BY fb.valid_year DESC, fb.movie_id ASC
FETCH FIRST 100 ROWS ONLY;