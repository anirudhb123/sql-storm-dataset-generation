WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select top-level movies (those without a parent episode)
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_id,
        0 AS level
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL

    UNION ALL

    -- Recursive case: Select episodes for each movie
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1 AS level
    FROM aka_title mt
    JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
-- CTE to calculate average ratings assuming there is a ratings table
AverageRatings AS (
    SELECT 
        movie_id,
        AVG(rating) AS avg_rating
    FROM ratings
    GROUP BY movie_id
),
-- CTE for getting the cast and their roles
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
),
-- CTE for filtering titles based on specific keywords
FilteredTitles AS (
    SELECT 
        at.id AS title_id,
        at.title
    FROM aka_title at
    JOIN movie_keyword mk ON at.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword ILIKE '%drama%' OR k.keyword ILIKE '%thriller%'
)
-- Main query to pull together data with outer joins and complex predicates
SELECT 
    mh.movie_id,
    mh.title AS movie_title,
    mh.production_year,
    COALESCE(ar.actor_name, 'No Cast') AS actor_name,
    COALESCE(ar.role, 'Unknown Role') AS actor_role,
    COALESCE(ar.actor_order, 999) AS role_order,
    COALESCE(fr.title, 'No Related Titles') AS related_title,
    COALESCE(ar.level, 0) AS hierarchy_level,
    COALESCE(ar.avg_rating, 'No Ratings') AS average_rating,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM MovieHierarchy mh
LEFT JOIN ActorRoles ar ON mh.movie_id = ar.movie_id
LEFT JOIN FilteredTitles fr ON mh.movie_id = fr.title_id
LEFT JOIN AverageRatings avg ON mh.movie_id = avg.movie_id
ORDER BY mh.production_year DESC, ar.actor_order ASC;
