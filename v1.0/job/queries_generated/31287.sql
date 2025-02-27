WITH RECURSIVE Movie_Hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        aka_title mt
    INNER JOIN 
        Movie_Hierarchy mh ON mt.episode_of_id = mh.movie_id
),
Ranked_Cast AS (
    SELECT 
        ci.person_id, 
        ci.movie_id, 
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_roles
    FROM 
        cast_info ci
),
Movie_Keywords AS (
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
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT rc.person_id) AS total_cast,
    SUM(CASE WHEN rc.role_rank = 1 THEN 1 ELSE 0 END) AS main_roles,
    COALESCE(mk.keywords, 'No Keywords') AS keywords_list,
    (COUNT(DISTINCT rc.person_id) FILTER (WHERE rc.role_rank = 1) * 1.0 / NULLIF(COUNT(DISTINCT rc.person_id), 0)) AS main_role_percentage,
    mh.depth
FROM 
    Movie_Hierarchy mh
LEFT JOIN 
    Ranked_Cast rc ON mh.movie_id = rc.movie_id
LEFT JOIN 
    Movie_Keywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2000  
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mk.keywords, mh.depth
ORDER BY 
    main_role_percentage DESC, mh.production_year DESC
LIMIT 50;
