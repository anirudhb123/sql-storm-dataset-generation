WITH movie_summary AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS aliases,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT mk.keyword) AS total_keywords
    FROM title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    GROUP BY t.id
),
person_summary AS (
    SELECT 
        ak.person_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS roles_count,
        GROUP_CONCAT(DISTINCT ti.title ORDER BY ti.title) AS titles
    FROM aka_name ak
    LEFT JOIN cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN title ti ON ci.movie_id = ti.id
    GROUP BY ak.person_id
),
keyword_summary AS (
    SELECT 
        mk.keyword AS movie_keyword,
        COUNT(DISTINCT mk.movie_id) AS keyword_count,
        GROUP_CONCAT(DISTINCT t.title ORDER BY t.title) AS movies
    FROM movie_keyword mk
    LEFT JOIN title t ON mk.movie_id = t.id
    GROUP BY mk.keyword
)
SELECT 
    ms.movie_title,
    ms.production_year,
    ms.companies,
    ms.aliases,
    ms.total_cast,
    ms.total_keywords,
    ps.actor_name,
    ps.roles_count,
    ps.titles,
    ks.movie_keyword,
    ks.keyword_count,
    ks.movies
FROM movie_summary ms
LEFT JOIN person_summary ps ON ms.total_cast > 0
LEFT JOIN keyword_summary ks ON ms.total_keywords > 0
ORDER BY ms.production_year DESC, ms.movie_title;
