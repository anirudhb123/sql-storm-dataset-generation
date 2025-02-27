
WITH RecursiveMovieInfo AS (
    SELECT mt.movie_id, mt.title, mt.production_year,
           mt.kind_id, 
           ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS row_num
    FROM aka_title mt
    WHERE mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
      AND mt.production_year IS NOT NULL
), 
PersonRoles AS (
    SELECT ci.movie_id, ak.person_id, ak.name AS actor_name,
           COUNT(DISTINCT ci.role_id) AS role_count
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN person_info pi ON ak.person_id = pi.person_id
    WHERE pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birthdate')
      AND ak.name IS NOT NULL
    GROUP BY ci.movie_id, ak.name, ak.person_id
), 
AggregateRoleCount AS (
    SELECT movie_id, 
           SUM(role_count) AS total_roles, 
           COUNT(DISTINCT person_id) AS total_actors
    FROM PersonRoles
    GROUP BY movie_id
),
MovieCompanyInfo AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS num_companies,
           STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE cn.country_code IS NOT NULL
    GROUP BY mc.movie_id
)

SELECT
    m.movie_id,
    m.title,
    m.production_year,
    r.total_roles,
    r.total_actors,
    c.num_companies,
    c.companies,
    CASE 
        WHEN r.total_roles > 10 THEN 'High'
        WHEN r.total_roles BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low' 
    END AS role_density,
    COALESCE(mk.keyword, 'No keywords') AS keyword_info
FROM RecursiveMovieInfo m
LEFT JOIN AggregateRoleCount r ON m.movie_id = r.movie_id
LEFT JOIN MovieCompanyInfo c ON m.movie_id = c.movie_id
LEFT JOIN LATERAL (
    SELECT STRING_AGG(DISTINCT k.keyword, ', ') AS keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE mk.movie_id = m.movie_id
) AS mk ON TRUE
WHERE m.production_year >= 2000
ORDER BY m.production_year DESC, m.title ASC
LIMIT 100;
