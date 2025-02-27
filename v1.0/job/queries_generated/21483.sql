WITH RecursiveActorMovies AS (
    SELECT ci.person_id, ci.movie_id, 1 AS level
    FROM cast_info ci
    WHERE ci.person_role_id IS NOT NULL
    UNION ALL
    SELECT ci.person_id, ci.movie_id, level + 1
    FROM cast_info ci
    INNER JOIN RecursiveActorMovies ram ON ci.movie_id = ram.movie_id
    WHERE ci.person_id <> ram.person_id
),
TitleWithMaxRoles AS (
    SELECT t.title, COUNT(DISTINCT ci.person_id) AS role_count
    FROM title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.title
    HAVING COUNT(DISTINCT ci.person_id) > 3
),
MoviesAndKeywords AS (
    SELECT m.id AS movie_id, m.title, k.keyword
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
),
DistinctCompanies AS (
    SELECT DISTINCT c.id, c.name
    FROM company_name c
    INNER JOIN movie_companies mc ON c.id = mc.company_id
    WHERE c.country_code IS NOT NULL
),
SelectedActors AS (
    SELECT DISTINCT a.id, a.name
    FROM aka_name a
    INNER JOIN cast_info ci ON a.person_id = ci.person_id
    WHERE EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = ci.movie_id
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
        AND mi.info IS NOT NULL
    )
)
SELECT 
    t.title,
    COALESCE(a.name, 'Unknown Actor') AS actor_name,
    COALESCE(dc.name, 'Unknown Company') AS company_name,
    COALESCE(mk.keyword, 'No Keyword') AS keyword,
    rmo.level AS actor_movie_level
FROM TitleWithMaxRoles t
LEFT JOIN RecursiveActorMovies rmo ON t.role_count < rmo.level
LEFT JOIN SelectedActors a ON rmo.person_id = a.id
LEFT JOIN DistinctCompanies dc ON dc.id = (SELECT company_id FROM movie_companies WHERE movie_id = t.movie_id LIMIT 1)
LEFT JOIN MoviesAndKeywords mk ON mk.movie_id = t.id
WHERE t.title IS NOT NULL
  AND (rmo.level IS NULL OR rmo.level > 1)
ORDER BY t.title, actor_name, company_name, keyword;

