WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        NULL::integer AS parent_movie_id
    FROM title t
    JOIN aka_title at ON t.id = at.movie_id
    JOIN movie_companies mc ON at.movie_id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE cn.country_code IS NULL OR cn.country_code = 'USA'
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        mh.movie_id AS parent_movie_id
    FROM title t
    JOIN movie_link ml ON t.id = ml.movie_id
    JOIN MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Vintage' 
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern' 
        ELSE 'Recent' 
    END AS era,
    COUNT(c.id) AS cast_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    AVG(mr.rating) AS avg_rating
FROM MovieHierarchy mh
LEFT JOIN cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN aka_name a ON c.person_id = a.person_id
LEFT JOIN (
    SELECT 
        mi.movie_id,
        AVG(NULLIF(mi.info::numeric, 0)) AS rating
    FROM movie_info mi
    WHERE mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    GROUP BY mi.movie_id
) mr ON mh.movie_id = mr.movie_id
WHERE (mh.production_year IS NULL OR mh.production_year > 1990) 
GROUP BY mh.title, mh.production_year
HAVING COUNT(c.id) > 0
ORDER BY 
    CASE 
        WHEN mh.production_year IS NULL THEN 1 
        ELSE 0 
    END,
    mh.production_year DESC;

