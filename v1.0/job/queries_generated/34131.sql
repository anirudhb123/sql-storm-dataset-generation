WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        ARRAY[mt.title] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1,
        mh.path || et.title
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
),

cast_roles AS (
    SELECT 
        ci.movie_id,
        ci.role_id,
        ct.kind AS role_name,
        COUNT(*) OVER(PARTITION BY ci.role_id) AS total_roles
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.title,
    mh.production_year,
    COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'No Cast') AS cast_members,
    COALESCE(r.role_name, 'Unknown Role') AS role_name,
    mk.keywords,
    mh.level,
    mh.path
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    cast_roles r ON ci.movie_id = r.movie_id AND r.total_roles > 5
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2000
GROUP BY 
    mh.movie_id, mh.title, mk.keywords, r.role_name, mh.production_year, mh.level, mh.path
ORDER BY 
    mh.production_year DESC, mh.level ASC;

This query performs the following operations:

- A recursive CTE `movie_hierarchy` is used to retrieve a list of movies and their nested episodes, along with a path that shows the hierarchy of episodes.
- A secondary CTE `cast_roles` calculates the number of roles per role type.
- Another CTE `movie_keywords` retrieves all keywords associated with each movie.
- The main `SELECT` statement combines results from these CTEs and joins them with the `aka_name` table to fetch cast members.
- The results are further filtered to only include movies produced after 2000, alongside various aggregations and a comprehensive order based on production year and hierarchy level.
- NULL logic is utilized to handle missing cast members, returning 'No Cast' in such cases.
- A `STRING_AGG` is employed to concatenate keywords and cast members for better readability.
