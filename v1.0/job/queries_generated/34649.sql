WITH RECURSIVE MovieHierachy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 0 AS level
    FROM aka_title m
    WHERE m.kind_id = 1 -- assuming 1 represents movies

    UNION ALL

    SELECT m.id, m.title, m.production_year, mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN MovieHierachy mh ON ml.movie_id = mh.movie_id
),
MovieRoles AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles,
        COUNT(DISTINCT ci.person_id) AS total_actors
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id
),
MoviesInfo AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(mr.roles, 'No roles assigned') AS roles,
        COALESCE(mr.total_actors, 0) AS total_actors
    FROM MovieHierachy mh
    LEFT JOIN MovieRoles mr ON mh.movie_id = mr.movie_id
)
SELECT
    mi.title,
    mi.production_year,
    mi.roles,
    mi.total_actors,
    n.name AS director_name,
    COUNT(k.keyword) AS keyword_count,
    COUNT(DISTINCT cc.person_id) AS total_people_in_companies
FROM MoviesInfo mi
LEFT JOIN movie_companies mc ON mi.movie_id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN movie_keyword mk ON mi.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN complete_cast cc ON cc.movie_id = mi.movie_id
LEFT JOIN cast_info ci ON ci.movie_id = mi.movie_id
LEFT JOIN aka_name n ON ci.person_id = n.person_id AND n.md5sum IS NOT NULL
WHERE mi.production_year > 2000
GROUP BY mi.title, mi.production_year, mi.roles, mi.total_actors, n.name
HAVING COUNT(DISTINCT cc.person_id) > 5
ORDER BY mi.production_year DESC, mi.total_actors DESC
LIMIT 10;

This query structure utilizes various advanced SQL constructs such as:
- A recursive Common Table Expression (CTE) to gather movie hierarchies.
- Aggregation with `STRING_AGG` for roles and `COUNT` for number of actors.
- Multiple joins including outer joins, and filtering conditions with `WHERE`.
- Grouping and having clauses to filter based on specified criteria.
- Sorting results for better readability and relevance.
