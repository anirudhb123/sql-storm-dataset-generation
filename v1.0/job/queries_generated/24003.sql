WITH RecursiveCasts AS (
    SELECT ci.movie_id, ci.person_id, ci.nr_order,
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM cast_info ci
    WHERE ci.note IS NULL
), 
FilteredMovies AS (
    SELECT m.title, m.production_year, m.id AS movie_id,
           (SELECT COUNT(DISTINCT ci.person_id) 
            FROM cast_info ci 
            WHERE ci.movie_id = m.id) AS distinct_cast_count
    FROM aka_title m
    WHERE m.production_year > 1990
), 
NamedRoles AS (
    SELECT ak.name AS actor_name, r.role AS role_name, ci.movie_id
    FROM ak_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN role_type r ON ci.role_id = r.id
    WHERE ak.name IS NOT NULL AND ak.name <> ''
), 
MovieKeywords AS (
    SELECT DISTINCT m.title, k.keyword
    FROM movie_keyword mk
    JOIN aka_title m ON mk.movie_id = m.id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE m.production_year BETWEEN 2000 AND 2020
), 
AggregateCompanies AS (
    SELECT mc.movie_id,
           STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
           COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT fm.title, fm.production_year, rc.role_order,
       nr.actor_name, nr.role_name, mk.keyword, ac.company_names,
       COALESCE(fm.distinct_cast_count, 0) AS distinct_cast_count,
       CASE WHEN fm.distinct_cast_count > 0 THEN 'Yes' ELSE 'No' END AS has_cast
FROM FilteredMovies fm
LEFT JOIN RecursiveCasts rc ON fm.movie_id = rc.movie_id
LEFT JOIN NamedRoles nr ON fm.movie_id = nr.movie_id
LEFT JOIN MovieKeywords mk ON fm.title = mk.title
LEFT JOIN AggregateCompanies ac ON fm.movie_id = ac.movie_id
WHERE (mk.keyword LIKE '%Action%' OR mk.keyword LIKE '%Drama%')
  AND (ac.company_count IS NULL OR ac.company_count > 1)
ORDER BY fm.production_year DESC, fm.title ASC, rc.role_order
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
