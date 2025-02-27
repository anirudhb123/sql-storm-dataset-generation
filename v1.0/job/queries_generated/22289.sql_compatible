
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year, 
        mt.kind_id,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
RecursiveAuthors AS (
    SELECT 
        ca.movie_id, 
        a.person_id, 
        a.name, 
        ca.role_id,
        COALESCE(NULLIF(LOWER(a.name), ''), 'Unknown') AS adjusted_name
    FROM 
        cast_info ca 
    JOIN 
        aka_name a ON a.person_id = ca.person_id
    LEFT JOIN 
        MovieHierarchy mh ON mh.movie_id = ca.movie_id
    WHERE 
        ca.nr_order IS NOT NULL
),
CoalescedInfo AS (
    SELECT 
        movie_id,
        STRING_AGG(DISTINCT adjusted_name, ', ') AS actor_names,
        COUNT(DISTINCT role_id) AS distinct_roles
    FROM 
        RecursiveAuthors
    GROUP BY 
        movie_id
),
OuterJoinedInfo AS (
    SELECT 
        mh.movie_id, 
        mh.movie_title,
        COALESCE(ci.actor_names, 'No cast') AS actors,
        COALESCE(ci.distinct_roles, 0) AS role_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CoalescedInfo ci ON mh.movie_id = ci.movie_id
)
SELECT 
    oj.movie_title, 
    mh.production_year, 
    oj.actors, 
    oj.role_count,
    CASE
        WHEN oj.role_count > 5 THEN 'Ensemble Cast'
        WHEN oj.role_count BETWEEN 1 AND 5 THEN 'Small Cast'
        ELSE 'No Cast'
    END AS cast_category,
    (SELECT 
        COUNT(*) 
     FROM 
        movie_info mi 
     WHERE 
        mi.movie_id = oj.movie_id 
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')) AS box_office_info_count
FROM 
    OuterJoinedInfo oj
JOIN 
    MovieHierarchy mh ON oj.movie_id = mh.movie_id
WHERE 
    mh.production_year >= 2000 
ORDER BY 
    mh.production_year DESC, 
    oj.movie_title ASC
FETCH FIRST 20 ROWS ONLY;
