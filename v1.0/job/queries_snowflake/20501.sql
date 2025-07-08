WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS depth,
        mt.production_year
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        mh.depth + 1,
        at.production_year
    FROM 
        movie_link ml
    INNER JOIN aka_title at ON ml.linked_movie_id = at.id
    INNER JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 5  
)

SELECT 
    m.*,
    coalesce(cast_count.cast_member_count, 0) AS cast_member_count,
    COALESCE(p.info_count, 0) AS info_type_count
FROM 
    MovieHierarchy m
LEFT JOIN (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS cast_member_count
    FROM 
        cast_info ci 
    GROUP BY 
        ci.movie_id
) cast_count ON m.movie_id = cast_count.movie_id
LEFT JOIN (
    SELECT 
        mi.movie_id, 
        COUNT(DISTINCT mi.info_type_id) AS info_count
    FROM 
        movie_info mi 
    GROUP BY 
        mi.movie_id
) p ON m.movie_id = p.movie_id
WHERE 
    m.production_year IS NOT NULL 
    AND (m.production_year > 2000 OR m.movie_title LIKE '%Mystery%') 
    AND NOT EXISTS (
        SELECT 1 
        FROM movie_keyword mk 
        WHERE mk.movie_id = m.movie_id 
        AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Banned%')
    )
ORDER BY 
    m.production_year DESC, 
    cast_member_count DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;