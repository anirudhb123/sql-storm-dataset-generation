WITH RECURSIVE MovieCTE AS (
    SELECT 
        mt1.id AS movie_id,
        mt1.title AS title,
        mt1.production_year,
        COALESCE(mt2.title, 'No Link') AS linked_movie_title,
        mt1.season_nr,
        mt1.episode_nr,
        mt1.imdb_index,
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mt1.id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mt1.production_year ORDER BY mt1.title) AS rn
    FROM 
        aka_title mt1
    LEFT JOIN 
        movie_link ml ON mt1.id = ml.movie_id
    LEFT JOIN 
        aka_title mt2 ON ml.linked_movie_id = mt2.id
    WHERE 
        mt1.kind_id IN (
            SELECT id FROM kind_type WHERE kind LIKE '%Drama%'
        )
    UNION ALL
    SELECT 
        mt.id AS movie_id,
        mt.title AS title,
        mt.production_year,
        COALESCE(ml.linked_movie_title, 'No Link') AS linked_movie_title,
        mt.season_nr,
        mt.episode_nr,
        mt.imdb_index,
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mt.id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rn
    FROM 
        aka_title mt
    INNER JOIN 
        MovieCTE mcte ON mt.production_year = mcte.production_year
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
)
SELECT 
    c.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    mt.keyword_count,
    CASE 
        WHEN mt.keyword_count > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity,
    mcc.kind AS company_type
FROM 
    cast_info ci
JOIN 
    aka_name c ON ci.person_id = c.person_id
JOIN 
    MovieCTE mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    movie_companies mc ON mt.movie_id = mc.movie_id
LEFT JOIN 
    company_type mcc ON mc.company_type_id = mcc.id
WHERE 
    c.name IS NOT NULL
    AND mt.production_year BETWEEN 2000 AND 2023
    AND (mcc.kind IS NOT NULL OR mcc.kind IS DISTINCT FROM 'Documentary')
ORDER BY 
    mt.production_year DESC, 
    popularity DESC, 
    actor_name;

This SQL query incorporates several advanced constructs such as a recursive CTE, outer joins, window functions, correlated subqueries, and complex predicates. It’s designed to benchmark performance while providing useful insights about movies, their actors, and associated movie companies.
