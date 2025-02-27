WITH RECURSIVE ActorHierarchy AS (
    SELECT c.movie_id, c.person_id, a.name, 1 AS level
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE a.name IS NOT NULL

    UNION ALL

    SELECT ch.movie_id, ch.person_id, a.name, ah.level + 1
    FROM cast_info ch
    JOIN ActorHierarchy ah ON ch.movie_id = ah.movie_id
    JOIN aka_name a ON ch.person_id = a.person_id
    WHERE a.name IS NOT NULL AND ah.level < 5
),

MovieKeywords AS (
    SELECT m.movie_id, 
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN title m ON mk.movie_id = m.id
    GROUP BY m.movie_id
),

CompanyDetails AS (
    SELECT mc.movie_id, 
           c.name AS company_name, 
           ct.kind AS company_type,
           COUNT(*) AS total_movies
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, c.name, ct.kind
),

MovieInfoStats AS (
    SELECT ti.id AS movie_id,
           ti.title,
           COALESCE(kw.keywords, 'No Keywords') AS keywords,
           COALESCE(SUM(mk.info::integer), 0) AS total_info
    FROM title ti
    LEFT JOIN MovieKeywords kw ON ti.id = kw.movie_id
    LEFT JOIN movie_info_idx mk ON ti.id = mk.movie_id
    WHERE ti.production_year >= 2000
    GROUP BY ti.id, ti.title, kw.keywords
),

FinalResults AS (
    SELECT m.movie_id, 
           m.title, 
           m.keywords, 
           ch.name AS cast_member, 
           ch.level,
           cd.company_name,
           cd.company_type,
           mis.total_info
    FROM MovieInfoStats m
    LEFT JOIN ActorHierarchy ch ON m.movie_id = ch.movie_id
    LEFT JOIN CompanyDetails cd ON m.movie_id = cd.movie_id
    ORDER BY m.movie_id, ch.level
)

SELECT movie_id, 
       title, 
       keywords,
       STRING_AGG(DISTINCT cast_member, ', ') FILTER (WHERE cast_member IS NOT NULL) AS cast_members,
       MAX(company_name) AS company_name,
       MAX(company_type) AS company_type,
       MAX(total_info) AS total_info
FROM FinalResults
GROUP BY movie_id, title, keywords
HAVING MAX(total_info) > 10
ORDER BY movie_id;
