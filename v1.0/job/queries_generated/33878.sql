WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mc.company_id,
        c.name AS company_name,
        1 AS level
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        mt.production_year > 2000  -- Considering only movies produced after 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mc.company_id,
        c.name AS company_name,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        mh.level < 5  -- Limit recursion depth
)

SELECT 
    mh.title,
    mh.production_year,
    mh.level,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
    MAX(CASE WHEN i.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre') THEN i.info END) AS genre,
    SUM(CASE WHEN EXISTS (
                SELECT 1 
                FROM movie_keyword mk 
                WHERE mk.movie_id = mh.movie_id AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword IN ('Action', 'Comedy'))
            )
            THEN 1 ELSE 0 END) AS keyword_match_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_info i ON mh.movie_id = i.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    mh.production_year DESC, mh.total_cast DESC;
