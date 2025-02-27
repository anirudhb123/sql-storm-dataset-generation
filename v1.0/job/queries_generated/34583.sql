WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  -- Select root movies

    UNION ALL

    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title mt
    INNER JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id  -- Recursive join for episodes
),

cast_details AS (
    SELECT 
        ca.movie_id,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    GROUP BY 
        ca.movie_id
),

rating_info AS (
    SELECT 
        mi.movie_id,
        CASE 
            WHEN mi.info IS NULL THEN 'No Rating'
            ELSE mi.info
        END AS rating
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info = 'rating'
),

movie_companies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cd.actor_count, 0) AS actor_count,
    COALESCE(cd.actors, 'No Actors') AS actors,
    COALESCE(ri.rating, 'No Rating') AS rating,
    COALESCE(mc.companies, 'No Companies') AS companies,
    mh.level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    rating_info ri ON mh.movie_id = ri.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
ORDER BY 
    mh.production_year DESC, 
    mh.title;
This query combines several advanced SQL concepts, including a recursive common table expression (CTE) to construct a hierarchy of movies and their episodes, while also aggregating cast details, ratings, and production companies. The use of outer joins ensures we capture all movies even if they have no actors, ratings, or companies associated with them. The final result set provides a comprehensive overview of each movie's information, sorted by production year and title.
