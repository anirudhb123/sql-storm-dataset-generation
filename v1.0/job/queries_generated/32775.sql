WITH RECURSIVE movie_hierarchy AS (
    -- CTE to build a recursive hierarchy of movies and their links (if any)
    SELECT 
        ml.movie_id AS root_movie_id,
        ml.linked_movie_id AS sub_movie_id,
        1 AS depth
    FROM movie_link ml
    WHERE ml.link_type_id = 1  -- Assuming '1' corresponds to a specific link type

    UNION ALL

    SELECT 
        mh.root_movie_id,
        ml.linked_movie_id,
        mh.depth + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.sub_movie_id
    WHERE mh.depth < 3  -- Limit to 3 levels deep
),

ranked_movies AS (
    -- CTE to rank movies based on the number of distinct characters in the cast and their roles
    SELECT 
        ak.title,
        COUNT(DISTINCT ci.person_id) AS num_distinct_cast,
        RANK() OVER (ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS role_rank
    FROM aka_title ak
    JOIN cast_info ci ON ak.movie_id = ci.movie_id
    LEFT JOIN movie_hierarchy mh ON ak.movie_id = mh.root_movie_id
    GROUP BY ak.title
),

movie_info_extended AS (
    -- CTE to fetch movie information including keywords, companies, and additional info
    SELECT 
        at.title,
        at.production_year,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        MIN(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS director_info,  -- Assuming 1 is the director info type
        MAX(CASE WHEN mi.info_type_id = 2 THEN mi.info END) AS genre_info          -- Assuming 2 is the genre info type
    FROM aka_title at
    LEFT JOIN movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN movie_companies mc ON at.movie_id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN movie_info mi ON at.movie_id = mi.movie_id
    GROUP BY at.title, at.production_year
)

SELECT 
    mhe.root_movie_id,
    mhe.sub_movie_id,
    miex.title,
    miex.production_year,
    miex.keywords,
    miex.companies,
    rm.num_distinct_cast,
    rm.role_rank
FROM movie_hierarchy mhe
JOIN ranked_movies rm ON mhe.sub_movie_id = rm.title
JOIN movie_info_extended miex ON mhe.root_movie_id = miex.title
WHERE miex.production_year >= 2000  -- Filter for movies produced from 2000 onwards
  AND rm.role_rank <= 10              -- Limit to top 10 by distinct cast count
ORDER BY mhe.root_movie_id, rm.role_rank;
