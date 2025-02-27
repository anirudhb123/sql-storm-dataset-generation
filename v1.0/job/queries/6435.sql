
WITH MovieYear AS (
    SELECT t.id AS movie_id, t.title, t.production_year, STRING_AGG(DISTINCT k.keyword, ',') AS keywords
    FROM aka_title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year
    HAVING t.production_year BETWEEN 2000 AND 2020
), ActorMovie AS (
    SELECT c.movie_id, a.name AS actor_name, r.role
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
), CompanyDetails AS (
    SELECT mc.movie_id, comp.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name comp ON mc.company_id = comp.id
    JOIN company_type ct ON mc.company_type_id = ct.id
), FullMovieInfo AS (
    SELECT MY.movie_id, MY.title, MY.production_year, AM.actor_name, AM.role, CD.company_name, CD.company_type
    FROM MovieYear MY
    JOIN ActorMovie AM ON MY.movie_id = AM.movie_id
    JOIN CompanyDetails CD ON MY.movie_id = CD.movie_id
)
SELECT movie_id, title, production_year, actor_name, role, company_name, company_type
FROM FullMovieInfo
WHERE production_year = (
    SELECT MAX(production_year) FROM FullMovieInfo
)
ORDER BY actor_name, company_name;
