WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id, mt.title, 0 AS depth
    FROM aka_title mt
    WHERE mt.production_year = (
        SELECT MAX(production_year)
        FROM aka_title
    )
    
    UNION ALL
    
    SELECT ml.linked_movie_id AS movie_id, at.title, mh.depth + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_roles AS (
    SELECT ci.movie_id, COUNT(DISTINCT ci.role_id) AS role_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
top_movies AS (
    SELECT
        mh.movie_id,
        mh.title,
        COALESCE(cr.role_count, 0) AS role_count,
        RANK() OVER (ORDER BY mh.depth, COALESCE(cr.role_count, 0) DESC) AS rank
    FROM movie_hierarchy mh
    LEFT JOIN cast_roles cr ON mh.movie_id = cr.movie_id
)
SELECT
    tm.title,
    tm.role_count,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = tm.movie_id AND mc.company_type_id IN 
        (SELECT id FROM company_type WHERE kind = 'Production')) AS production_company_count,
    CASE
        WHEN tm.role_count IS NULL THEN 'No Roles'
        ELSE 'Has Roles'
    END AS role_status
FROM top_movies tm
WHERE tm.rank <= 10
ORDER BY tm.rank;
