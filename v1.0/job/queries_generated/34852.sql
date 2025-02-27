WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        1 AS level,
        m.production_year,
        0 AS is_root
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA' AND 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        t.title AS movie_title,
        mh.level + 1,
        mh.production_year,
        1 AS is_root
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
    WHERE 
        mh.level < 5
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COALESCE(cast_count.cast_count, 0) AS cast_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    CASE 
        WHEN mh.production_year > 2010 THEN 'Modern'
        ELSE 'Classic'
    END AS era,
    COUNT(DISTINCT co.id) AS company_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies co ON mh.movie_id = co.movie_id
LEFT JOIN 
    (SELECT 
        movie_id, COUNT(*) AS cast_count 
     FROM 
        cast_info 
     GROUP BY 
        movie_id) AS cast_count ON mh.movie_id = cast_count.movie_id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, mh.is_root
ORDER BY 
    mh.production_year DESC, 
    mh.movie_title;
