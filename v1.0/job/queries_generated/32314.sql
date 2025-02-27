WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY[t.title] AS title_path
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        mh.title_path || m.title
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG(mi.info_length) AS avg_info_length,
    COUNT(DISTINCT mc.company_id) AS companies_count,
    COUNT(DISTINCT ci.id) FILTER (WHERE ci.nr_order IS NOT NULL) AS cast_count,
    CASE WHEN AVG(mi.info_length) IS NULL THEN 'No Info' ELSE NULL END AS info_status
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    (
        SELECT 
            movie_id, 
            LENGTH(info) AS info_length 
        FROM 
            movie_info 
        WHERE 
            note IS NOT NULL
    ) mi ON mh.movie_id = mi.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC,
    keyword_count DESC;
