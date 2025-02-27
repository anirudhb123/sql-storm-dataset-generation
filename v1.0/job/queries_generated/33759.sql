WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    mh.title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS actor_count,
    AVG(COALESCE(mk.keyword_length, 0)) AS avg_keyword_length,
    STRING_AGG(DISTINCT co.name, ', ') AS company_names,
    MAX(CASE WHEN pi.info_type_id = 1 THEN pi.info END) AS personal_info,
    SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS cast_order_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    person_info pi ON c.person_id = pi.person_id
GROUP BY 
    mh.title, 
    mh.production_year
ORDER BY 
    avg_keyword_length DESC,
    actor_count DESC
LIMIT 10;

This SQL query constructs a recursive Common Table Expression (CTE) called `MovieHierarchy` to find movies produced after 2000 and their linked titles. It then aggregates important data such as actor counts, average keyword lengths, associated company names, personal information per cast member, and counts of non-null ordering in the cast. The use of outer joins allows for the inclusion of all movies in the hierarchy even if they lack certain data. The query concludes by sorting results on average keyword lengths and actor counts, with a limit on the output to the top 10 entries.
