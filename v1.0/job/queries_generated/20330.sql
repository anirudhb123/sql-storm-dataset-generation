WITH RecursiveMovieInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        a.person_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY a.nr_order) AS actor_rank
    FROM aka_title AS mt
    JOIN cast_info AS a ON mt.id = a.movie_id
    JOIN aka_name AS ak ON a.person_id = ak.person_id
 WHERE mt.production_year BETWEEN 2000 AND 2020
),

MovieGenres AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM movie_keyword AS mk
    JOIN keyword AS kw ON mk.keyword_id = kw.id
    GROUP BY mk.movie_id
),

MovieCompanies AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        SUM(CASE WHEN ct.kind = 'Distributor' THEN 1 ELSE 0 END) AS distributor_count
    FROM movie_companies AS mc
    JOIN company_name AS c ON mc.company_id = c.id
    JOIN company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
),

ActorsInMultipleMovies AS (
    SELECT
        ak.person_id,
        COUNT(DISTINCT a.movie_id) AS movies_count
    FROM cast_info AS a
    JOIN aka_name AS ak ON a.person_id = ak.person_id
    GROUP BY ak.person_id
    HAVING COUNT(DISTINCT a.movie_id) > 5
)

SELECT 
    r.movie_id,
    r.movie_title,
    r.actor_name,
    r.actor_rank,
    COALESCE(mg.keywords, 'No Keywords') AS keywords,
    COALESCE(mc.company_count, 0) AS company_count,
    COALESCE(mc.distributor_count, 0) AS distributor_count
FROM RecursiveMovieInfo AS r
LEFT JOIN MovieGenres AS mg ON r.movie_id = mg.movie_id
LEFT JOIN MovieCompanies AS mc ON r.movie_id = mc.movie_id
WHERE r.actor_rank <= 3
  AND r.actor_name IS NOT NULL
  AND r.actor_name NOT LIKE '%John%'
  AND r.actor_name NOT IN (SELECT ak.name FROM aka_name ak WHERE ak.name LIKE '%Smith%')
  AND EXISTS (SELECT 1 FROM ActorsInMultipleMovies am WHERE am.person_id = r.person_id)
ORDER BY r.movie_id, r.actor_rank;
