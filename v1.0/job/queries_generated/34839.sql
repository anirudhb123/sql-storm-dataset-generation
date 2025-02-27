WITH RECURSIVE FilmHierarchy AS (
    SELECT t.id AS film_id, t.title, t.production_year, 1 AS level
    FROM aka_title t
    WHERE t.production_year IS NOT NULL

    UNION ALL

    SELECT t.id, t.title, t.production_year, fh.level + 1
    FROM aka_title t
    JOIN FilmHierarchy fh ON t.episode_of_id = fh.film_id
),

FilteredMovies AS (
    SELECT f.film_id, f.title, f.production_year
    FROM FilmHierarchy f
    WHERE f.production_year > 2000
),

MovieKeywords AS (
    SELECT km.movie_id, k.keyword
    FROM movie_keyword km
    JOIN keyword k ON km.keyword_id = k.id
),

PersonalRoles AS (
    SELECT ci.movie_id, c.name AS actor_name, r.role AS role_name, ci.nr_order
    FROM cast_info ci
    JOIN aka_name c ON ci.person_id = c.person_id
    JOIN role_type r ON ci.role_id = r.id
),

MovieCompanies AS (
    SELECT mc.movie_id, co.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),

RankedMovies AS (
    SELECT 
        fm.title,
        fm.production_year,
        COUNT(DISTINCT km.keyword) AS keyword_count,
        STRING_AGG(DISTINCT pr.actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT mc.company_name, ', ') AS production_companies,
        ROW_NUMBER() OVER (PARTITION BY fm.production_year ORDER BY COUNT(DISTINCT km.keyword) DESC) AS rank
    FROM FilteredMovies fm
    LEFT JOIN MovieKeywords km ON fm.film_id = km.movie_id
    LEFT JOIN PersonalRoles pr ON fm.film_id = pr.movie_id
    LEFT JOIN MovieCompanies mc ON fm.film_id = mc.movie_id
    GROUP BY fm.film_id, fm.title, fm.production_year
)

SELECT 
    rm.title,
    rm.production_year,
    rm.keyword_count,
    rm.actors,
    rm.production_companies,
    COALESCE(rm.rank, 'N/A') AS movie_rank
FROM RankedMovies rm
WHERE rm.keyword_count > 2 AND rm.rank IS NOT NULL
ORDER BY rm.production_year DESC, rm.keyword_count DESC
LIMIT 10;
