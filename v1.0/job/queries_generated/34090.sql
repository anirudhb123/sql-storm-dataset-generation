WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        ROW_NUMBER() OVER (PARTITION BY mh.depth ORDER BY mh.title) AS rank
    FROM 
        movie_hierarchy mh
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 10
),
cast_overview AS (
    SELECT 
        ca.movie_id,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN co.kind = 'Lead' THEN ca.person_id END) AS lead_cast
    FROM 
        cast_info ca
    JOIN 
        comp_cast_type co ON ca.person_role_id = co.id
    GROUP BY 
        ca.movie_id
)
SELECT 
    tm.title,
    ISNULL(co.total_cast, 0) AS total_cast,
    ISNULL(co.lead_cast, 0) AS lead_cast,
    COALESCE(mi.info, 'No Info Available') AS additional_info,
    EXTRACT(YEAR FROM t.production_year) AS release_year,
    CASE 
        WHEN co.total_cast IS NULL THEN 'No Cast Data'
        WHEN co.lead_cast = 0 THEN 'No Lead Cast'
        ELSE 'Data Available'
    END AS cast_data_status
FROM 
    top_movies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_overview co ON tm.movie_id = co.movie_id
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
LEFT JOIN 
    aka_title t ON tm.movie_id = t.id
WHERE 
    t.production_year IS NOT NULL 
    AND t.production_year >= 2000
ORDER BY 
    release_year DESC, total_cast DESC;
