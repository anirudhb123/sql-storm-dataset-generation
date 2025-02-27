SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    ct.kind AS company_type,
    mi.info AS movie_info,
    k.keyword AS movie_keyword,
    COUNT(DISTINCT cc.subject_id) AS total_cast_members,
    MAX(t.production_year) AS latest_production_year
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info cc ON t.id = cc.movie_id
JOIN 
    aka_name ak ON cc.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ak.name ILIKE '%Smith%' -- Filter for actors with "Smith" in their name
    AND t.production_year > 2000 -- Filter for movies produced after the year 2000
GROUP BY 
    t.title, ak.name, ct.kind, mi.info, k.keyword
ORDER BY 
    total_cast_members DESC, latest_production_year DESC
LIMIT 50;

This query performs complex joining operations across multiple tables within the "Join Order Benchmark" schema, filtering on specific string patterns within actor names and production years. It aggregates data to count distinct cast members, making it suitable for benchmarking string processing performance.
