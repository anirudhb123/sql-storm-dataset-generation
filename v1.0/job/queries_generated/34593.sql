WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id, a.name AS actor_name, 1 AS level
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE ci.movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000)

    UNION ALL

    SELECT ci.person_id, a.name, ah.level + 1
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN ActorHierarchy ah ON ci.movie_id = ah.person_id
    WHERE ci.movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000)
),
TitleKeyword AS (
    SELECT at.title, k.keyword
    FROM aka_title at
    JOIN movie_keyword mk ON at.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE at.production_year = 2020
),
CompanyInfo AS (
    SELECT mc.movie_id, cn.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE cn.country_code = 'USA'
),
MovieDetails AS (
    SELECT 
        t.title,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COALESCE(cn.name, 'Independent') AS production_company,
        YEAR(CURRENT_DATE) - t.production_year AS age
    FROM aka_title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    WHERE t.production_year < 2023
    GROUP BY t.id, t.title, cn.name
)
SELECT 
    md.title,
    md.keywords,
    md.cast_count,
    md.production_company,
    md.age,
    ah.actor_name
FROM MovieDetails md
LEFT JOIN ActorHierarchy ah ON md.cast_count >= 3
ORDER BY md.age DESC, md.title;
