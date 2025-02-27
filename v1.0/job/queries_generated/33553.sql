WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title mt 
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title mt 
    JOIN 
        movie_hierarchy mh 
    ON 
        mt.episode_of_id = mh.movie_id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ct.kind AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS actor_position
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info_subset AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Budget' THEN mi.info ELSE NULL END) AS budget,
        MAX(CASE WHEN it.info = 'Revenue' THEN mi.info ELSE NULL END) AS revenue
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(mis.budget, 'N/A') AS budget,
    COALESCE(mis.revenue, 'N/A') AS revenue,
    COALESCE(cd.actor_name, 'No actors') AS actor_name,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    (SELECT COUNT(*) 
     FROM cast_info ci_sub 
     WHERE ci_sub.movie_id = mh.movie_id) AS total_cast
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_info_subset mis ON mh.movie_id = mis.movie_id
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id AND cd.actor_position <= 3
LEFT JOIN 
    movie_keywords mk ON mh.movie_id = mk.movie_id
ORDER BY 
    mh.production_year DESC, mh.title;

**Explanation:**
1. **CTE (Recursive)**: `movie_hierarchy` builds a hierarchy of movies and their corresponding episodes.
2. **CTE**: `cast_details` gathers actor names and their roles for each movie.
3. **CTE**: `movie_keywords` aggregates keywords associated with movies.
4. **CTE**: `movie_info_subset` retrieves budget and revenue for each movie, ensuring NULL handling.
5. **Final SELECT**: Combines results using LEFT JOINs to include movies that may not have associated data in other tables.
6. **Calculations and Aggregation**: Uses window functions to limit the number of actors returned and performs aggregations for descriptive movie data.
7. **Ordering**: Sorts the output by production year and title for easier reading.
