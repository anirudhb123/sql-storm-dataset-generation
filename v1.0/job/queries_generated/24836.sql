WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
, ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.depth,
        RANK() OVER (PARTITION BY mh.depth ORDER BY mh.production_year DESC) AS rank
    FROM 
        movie_hierarchy mh
)
SELECT 
    mv.title,
    mv.production_year,
    COALESCE(a.name, 'Unknown') AS actor_name,
    c.name AS company_name,
    ROW_NUMBER() OVER (PARTITION BY mv.movie_id ORDER BY r.rank) AS movie_rank,
    COUNT(DISTINCT ke.keyword) FILTER (WHERE ke.keyword IS NOT NULL) AS keyword_count,
    STRING_AGG(DISTINCT CONCAT(ke.keyword, ' (' ,cnt.cnt, ')') ORDER BY cnt.cnt DESC) AS keyword_details
FROM 
    ranked_movies mv
LEFT JOIN 
    cast_info ci ON ci.movie_id = mv.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mv.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mv.movie_id
LEFT JOIN 
    keyword ke ON mk.keyword_id = ke.id
LEFT JOIN (
    SELECT 
        keyword_id,
        COUNT(*) AS cnt
    FROM 
        movie_keyword
    GROUP BY 
        keyword_id
) cnt ON mk.keyword_id = cnt.keyword_id
WHERE 
    mv.production_year > 2000
GROUP BY 
    mv.movie_id, mv.title, mv.production_year, a.name, c.name, r.rank
ORDER BY 
    mv.production_year DESC, movie_rank DESC
LIMIT 50;
This SQL query generates a comprehensive view of movies produced after the year 2000, their associated actors, companies, and keywords, while leveraging various SQL constructs such as CTEs, window functions, outer joins, and aggregation techniques. The output includes not only a ranking of movies by production year but also a detailed breakdown of keywords with their counts.
