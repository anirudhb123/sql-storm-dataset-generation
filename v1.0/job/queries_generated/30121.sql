WITH RECURSIVE MovieHierarchy AS (
    SELECT t.id AS movie_id, t.title, t.production_year, NULL::integer AS parent_id
    FROM aka_title t
    WHERE t.production_year >= 2020
    UNION ALL
    SELECT m.movie_id, t.title, t.production_year, m.movie_id AS parent_id
    FROM movie_link m
    JOIN aka_title t ON m.linked_movie_id = t.id
    JOIN MovieHierarchy mh ON m.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS role_rank,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM MovieHierarchy mh
    LEFT JOIN cast_info c ON mh.movie_id = c.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year
),
TopMovies AS (
    SELECT *
    FROM RankedMovies
    WHERE role_rank = 1
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    cs.company_count,
    cs.company_names
FROM TopMovies tm
LEFT JOIN CompanyStats cs ON tm.movie_id = cs.movie_id
WHERE COALESCE(cs.company_count, 0) > 0
ORDER BY tm.production_year DESC, tm.actor_count DESC;
