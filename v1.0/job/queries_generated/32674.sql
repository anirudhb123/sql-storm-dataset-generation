WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(NULLIF(mt.episode_of_id, 0), mt.id) AS root_movie_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.season_nr IS NOT NULL

    UNION ALL

    SELECT 
        mn.movie_id,
        mn.title,
        mn.production_year,
        mh.root_movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mn ON ml.linked_movie_id = mn.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mv.title AS movie_title,
    mv.production_year,
    ak.name AS actor_name,
    ct.kind AS role,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    SUM(NULLIF(mk.keyword IS NOT NULL, 0)::int) AS num_keywords,
    RANK() OVER (PARTITION BY mv.root_movie_id ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank_by_company_count
FROM 
    movie_hierarchy mv
JOIN 
    complete_cast cc ON mv.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON mv.movie_id = mc.movie_id
JOIN 
    movie_keyword mk ON mv.movie_id = mk.movie_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
WHERE 
    mv.production_year BETWEEN 2000 AND 2023
    AND ak.name IS NOT NULL
    AND ct.kind IS NOT NULL
GROUP BY 
    mv.movie_id, mv.title, mv.production_year, ak.name, ct.kind
HAVING 
    COUNT(DISTINCT mc.company_id) > 2
ORDER BY 
    rank_by_company_count, mv.production_year DESC;

This SQL query performs the following tasks:

1. A recursive CTE named `movie_hierarchy` is created to gather movies from a specific hierarchy based on seasons and episodes.
2. The main query selects relevant movie information, including the title, production year, actor names, roles, the number of associated companies, and keywords.
3. It joins several tables, including `complete_cast`, `cast_info`, `aka_name`, `movie_companies`, and `movie_keyword`, to accumulate the required data.
4. It groups results while calculating the number of distinct companies and keywords for filtering, specifically only including movies from 2000 to 2023 that have more than two distinct companies associated with them.
5. The results are ordered by the number of companies in descending order and then by the production year.
