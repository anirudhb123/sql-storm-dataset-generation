WITH RECURSIVE cast_hierarchy AS (
    SELECT ci.id, ci.person_id, ci.movie_id, ci.nr_order, ci.role_id
    FROM cast_info ci
    WHERE ci.nr_order = 1
    UNION ALL
    SELECT ci.id, ci.person_id, ci.movie_id, ci.nr_order, ci.role_id
    FROM cast_info ci
    INNER JOIN cast_hierarchy ch ON ci.movie_id = ch.movie_id AND ci.nr_order = ch.nr_order + 1
),
movies_with_keywords AS (
    SELECT mt.id AS movie_id, mt.title, ARRAY_AGG(mk.keyword) AS keywords
    FROM aka_title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY mt.id
),
company_movies AS (
    SELECT mc.movie_id, cn.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
movie_info_summary AS (
    SELECT mi.movie_id, STRING_AGG(DISTINCT it.info) AS details
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mi.movie_id
)
SELECT 
    mt.title AS movie_title,
    ak.name AS actor_name,
    ch.nr_order AS cast_order,
    kw.keywords,
    cm.company_name,
    cm.company_type,
    mis.details AS movie_details
FROM 
    movies_with_keywords kw
JOIN 
    cast_hierarchy ch ON kw.movie_id = ch.movie_id
JOIN 
    aka_name ak ON ch.person_id = ak.person_id
JOIN 
    company_movies cm ON kw.movie_id = cm.movie_id
JOIN 
    movie_info_summary mis ON kw.movie_id = mis.movie_id
WHERE 
    mt.production_year >= 2000
ORDER BY 
    mt.title, ch.nr_order;
