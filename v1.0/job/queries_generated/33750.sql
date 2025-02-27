WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3  -- limit depth of recursion to 3 levels
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    coalesce(string_agg(DISTINCT c.name, ', '), 'No Cast') AS cast_names,
    count(DISTINCT k.keyword) AS keyword_count,
    case 
        when count(DISTINCT k.keyword) > 5 then 'Popular'
        else 'Less Popular'
    end AS popularity_status,
    case 
        when m.production_year IS NULL then 'Unknown Year'
        else m.production_year::text
    end AS display_year
FROM 
    movie_hierarchy m
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name c ON ci.person_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    count(DISTINCT ci.id) > 0
ORDER BY 
    m.production_year DESC,
    popularity_status DESC;

