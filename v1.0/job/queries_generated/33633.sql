WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           1 AS depth
    FROM aka_title m
    WHERE m.production_year BETWEEN 2000 AND 2023

    UNION ALL

    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           mh.depth + 1
    FROM aka_title m
    INNER JOIN movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

ActorRoles AS (
    SELECT c.movie_id,
           a.name AS actor_name,
           r.role AS role_name,
           COUNT(*) OVER (PARTITION BY a.id ORDER BY c.nr_order) AS role_count
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
),

TitleKeywordInfo AS (
    SELECT t.title,
           GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.title
),

CountryCompany AS (
    SELECT c.name AS company_name,
           COUNT(m.id) AS movie_count
    FROM company_name c
    JOIN movie_companies mc ON c.id = mc.company_id
    JOIN aka_title m ON mc.movie_id = m.id
    GROUP BY c.name
    HAVING COUNT(m.id) >= 5
)

SELECT mh.movie_id,
       mh.title,
       mh.production_year,
       COALESCE(ar.actor_name, 'Unknown Actor') AS actor_name,
       COALESCE(ar.role_name, 'Unknown Role') AS role_name,
       COALESCE(tki.keywords, 'No Keywords') AS movie_keywords,
       ccc.company_name,
       ccc.movie_count
FROM MovieHierarchy mh
LEFT JOIN ActorRoles ar ON mh.movie_id = ar.movie_id
LEFT JOIN TitleKeywordInfo tki ON mh.title = tki.title
LEFT JOIN CountryCompany ccc ON ccc.movie_count = (SELECT MAX(movie_count) FROM CountryCompany)
ORDER BY mh.production_year DESC, mh.title;

This SQL query involves several advanced constructs:
- A **recursive Common Table Expression (CTE)** called `MovieHierarchy` retrieves movies released between 2000 and 2023, while allowing for linking associated movies.
- An **aggregate function** grouped with `COUNT` and **window functions** in the `ActorRoles` CTE to get the count of roles per actor while maintaining their order.
- The `TitleKeywordInfo` CTE uses a **string aggregation function** (GROUP_CONCAT) to compile a list of keywords for each movie title.
- The `CountryCompany` CTE counts movies produced by companies, filtering for companies with at least five movies.
- The final query **joins** these CTEs together using **outer joins**, and it provides a comprehensive overview of movies, including actors, roles, keywords, and the highest-producing company within the results. It incorporates **NULL logic** with COALESCE to handle potential missing values gracefully.
