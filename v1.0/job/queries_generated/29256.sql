WITH ActorTitles AS (
    SELECT a.id AS actor_id, a.name AS actor_name, t.title AS movie_title, t.production_year, rt.role AS role
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.id
    JOIN role_type rt ON c.role_id = rt.id
),
GenreKeywords AS (
    SELECT t.id AS title_id, t.title, k.keyword
    FROM aka_title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
),
TitleCompanyInfo AS (
    SELECT t.id AS title_id, t.title, c.name AS company_name, ct.kind AS company_type
    FROM aka_title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
FullBenchmarkInfo AS (
    SELECT 
        at.actor_name,
        at.movie_title,
        at.production_year,
        at.role,
        g.keyword,
        tc.company_name,
        tc.company_type
    FROM ActorTitles at
    LEFT JOIN GenreKeywords g ON at.movie_title = g.title
    LEFT JOIN TitleCompanyInfo tc ON at.movie_title = tc.title
)
SELECT 
    actor_name,
    COUNT(DISTINCT movie_title) AS total_movies,
    COUNT(DISTINCT keyword) AS total_keywords,
    COUNT(DISTINCT company_name) AS total_companies,
    MAX(production_year) AS last_movie_year,
    STRING_AGG(DISTINCT role, ', ') AS roles
FROM FullBenchmarkInfo
GROUP BY actor_name
ORDER BY total_movies DESC, actor_name;
