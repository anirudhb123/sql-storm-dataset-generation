SELECT 
    a.title AS movie_title,
    a.production_year,
    ak.name AS actor_name,
    p.gender AS actor_gender,
    kc.keyword AS movie_keyword,
    GROUP_CONCAT(DISTINCT c.kind || ': ' || cc.name ORDER BY cc.name SEPARATOR ', ') AS companies_involved,
    AVG(mi.info) AS avg_movie_rating
FROM 
    aka_title AS a
JOIN 
    cast_info AS ci ON a.id = ci.movie_id
JOIN 
    aka_name AS ak ON ci.person_id = ak.person_id
JOIN 
    name AS p ON ak.person_id = p.imdb_id
JOIN 
    movie_keyword AS mk ON a.id = mk.movie_id
JOIN 
    keyword AS kc ON mk.keyword_id = kc.id
JOIN 
    movie_companies AS mc ON a.id = mc.movie_id
JOIN 
    company_name AS cc ON mc.company_id = cc.id
JOIN 
    movie_info AS mi ON a.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
WHERE 
    a.production_year >= 2000 
    AND LENGTH(ak.name) > 3 
    AND (kc.keyword ILIKE '%action%' OR kc.keyword ILIKE '%drama%')
GROUP BY 
    a.id, ak.name, p.gender, kc.keyword
ORDER BY 
    a.production_year DESC, a.title;

This SQL query benchmarks string processing capabilities by performing a variety of joins across the provided schema. The query aggregates movie data from the `aka_title`, `cast_info`, `aka_name`, `name`, `movie_keyword`, `keyword`, `movie_companies`, `company_name`, and `movie_info` tables while applying conditions on the production year and name length. It groups the results by relevant identifiers and orders the output by production year and movie title. The use of string functions, `GROUP_CONCAT`, and LIKE patterns for filtering keywords allows for comprehensive string processing evaluation.
