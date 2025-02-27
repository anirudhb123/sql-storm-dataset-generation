WITH RECURSIVE MovieHierarchy AS (
    -- Base case: start with the root movie entries
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    -- Recursive case: join movies with their linked movies
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

, TitleKeywordCounts AS (
    SELECT
        title.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title title
    LEFT JOIN 
        movie_keyword mk ON title.id = mk.movie_id
    GROUP BY 
        title.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(tkc.keyword_count, 0) AS keyword_count,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT cn.name, ', ') AS cast_names
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id AND cn.country_code IS NOT NULL
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    TitleKeywordCounts tkc ON mh.movie_id = tkc.movie_id
WHERE 
    mh.production_year > 2000
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, tkc.keyword_count
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    mh.production_year DESC, keyword_count DESC, total_cast DESC
LIMIT 10;
