WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title, 
        mt.production_year,
        ARRAY[mt.title] AS title_path,
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
        mh.title_path || at.title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title at ON at.id = ml.linked_movie_id
    WHERE 
        mh.level < 5
        AND at.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        mh.movie_id, 
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY ARRAY_LENGTH(mh.title_path, 1) DESC) AS rank
    FROM 
        MovieHierarchy mh
    WHERE 
        mh.level = 5
)

SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    COALESCE(mc.company_name, 'Unknown') AS company_name,
    COALESCE(pi.info, 'No Info') AS person_info,
    COUNT(ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    SUM(CASE WHEN ci.nr_order IS NULL THEN 1 ELSE 0 END) AS null_orders,
    COUNT(CASE WHEN tv.title IS NOT NULL THEN 1 END) AS similar_titles_count
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON mc.movie_id = tm.movie_id
LEFT JOIN 
    person_info pi ON pi.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = tm.movie_id)
LEFT JOIN 
    cast_info ci ON ci.movie_id = tm.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    aka_title tv ON tv.title ILIKE '%' || tm.title || '%'
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, mc.company_name, pi.info, tm.title, tm.production_year
HAVING 
    COUNT(ci.person_id) > 0 
    AND tm.production_year > 2010
ORDER BY 
    tm.production_year DESC, cast_count DESC;
