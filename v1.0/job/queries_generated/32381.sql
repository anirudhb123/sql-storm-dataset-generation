WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        mc.linked_movie_id,
        at.title,
        at.production_year,
        mh.movie_id
    FROM 
        movie_link mc
    JOIN 
        aka_title at ON mc.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON mc.movie_id = mh.movie_id 
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    array_agg(DISTINCT c.name) AS cast,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    COALESCE(STATS.avg_rating, 0) AS avg_rating,
    COALESCE(cn.name, 'Unknown Company') AS production_company,
    COUNT(DISTINCT cl.id) FILTER (WHERE cl.link_type_id IS NOT NULL) AS linked_movies_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    (SELECT 
        movie_id, AVG(rating) as avg_rating
     FROM 
        movie_info
     WHERE 
        info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
     GROUP BY movie_id) STATS ON mh.movie_id = STATS.movie_id
LEFT JOIN 
    movie_link cl ON mh.movie_id = cl.movie_id
WHERE 
    mh.production_year >= 2000 AND
    (mh.title ILIKE '%Action%' OR mh.title ILIKE '%Drama%')
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, cn.name, STATS.avg_rating
ORDER BY 
    mh.production_year DESC, keyword_count DESC;
