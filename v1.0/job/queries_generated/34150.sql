WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL 

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year >= 2000
)

SELECT 
    ak.name AS actor_name,
    mt.movie_title,
    mt.production_year,
    COUNT(DISTINCT mcc.company_id) AS company_count,
    AVG(CASE WHEN music.info IS NOT NULL THEN 1 ELSE 0 END) AS has_music_info,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_companies mcc ON mt.id = mcc.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id AND it.info ILIKE '%music%'
LEFT JOIN 
    (SELECT 
         movie_id, info 
     FROM 
         movie_info 
     WHERE 
         info_type_id = (SELECT id FROM info_type WHERE info = 'Music')) music ON mt.id = music.movie_id
WHERE 
    mt.production_year >= 2000
GROUP BY 
    ak.name, mt.movie_title, mt.production_year
HAVING 
    COUNT(DISTINCT mcc.company_id) > 1
ORDER BY 
    mt.production_year DESC, ak.name;

This SQL query performs several operations including:

- A recursive Common Table Expression (CTE) named `MovieHierarchy` which constructs a hierarchy of movies and their links from the `aka_title` and `movie_link` tables.
- A main query that joins multiple tables (`cast_info`, `aka_name`, `aka_title`, `movie_companies`, etc.) to compile details about actors, their movies, associated companies, and keywords.
- It uses constructs like `LEFT JOIN`, `STRING_AGG` for aggregating keywords, `COUNT` for counting companies, and `AVG` combined with a `CASE` statement to analyze music info.
- It filters results for movies produced after the year 2000 and only returns actors associated with movies that have more than one production company.
- The result is ordered by production year and actor name for clarity in reporting.
