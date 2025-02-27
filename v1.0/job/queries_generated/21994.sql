WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM aka_title mt
    WHERE mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        lt.title,
        lt.production_year,
        mh.depth + 1
    FROM movie_link ml
    JOIN title lt ON ml.linked_movie_id = lt.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_stats AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(CASE WHEN ci.role_id = (SELECT id FROM role_type WHERE role = 'Actor') THEN 1 END) AS actor_count,
        COUNT(CASE WHEN ci.role_id = (SELECT id FROM role_type WHERE role = 'Director') THEN 1 END) AS director_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
highest_rated AS (
    SELECT 
        mi.movie_id,
        AVG(COALESCE(CAST(SUBSTRING(mi.info FROM 'Rating: (\d+\.\d+)') AS float), 0)) AS avg_rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info ILIKE '%rating%'
    GROUP BY mi.movie_id
),
movie_performance AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.depth,
        cs.total_cast,
        cs.actor_count,
        cs.director_count,
        COALESCE(hr.avg_rating, 0) AS avg_rating
    FROM movie_hierarchy mh
    LEFT JOIN cast_stats cs ON mh.movie_id = cs.movie_id
    LEFT JOIN highest_rated hr ON mh.movie_id = hr.movie_id
)
SELECT 
    mp.movie_id,
    mp.title,
    mp.production_year,
    mp.depth,
    mp.total_cast,
    mp.actor_count,
    mp.director_count,
    mp.avg_rating,
    CASE 
        WHEN mp.avg_rating IS NULL THEN 'No Rating'
        WHEN mp.avg_rating > 7 THEN 'Highly Rated'
        WHEN mp.avg_rating BETWEEN 5 AND 7 THEN 'Moderately Rated'
        ELSE 'Poorly Rated'
    END AS rating_category
FROM movie_performance mp
WHERE mp.total_cast > 0 AND mp.depth <= 2
ORDER BY mp.avg_rating DESC, mp.production_year DESC;

