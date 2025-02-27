SELECT 
    akn.name AS aka_name,
    ttl.title AS movie_title,
    p.name AS person_name,
    ct.kind AS role_type,
    m.year AS production_year,
    GROUP_CONCAT(kw.keyword) AS keywords,
    COUNT(DISTINCT cc.movie_id) AS total_movies_by_person,
    MIN(m.production_year) AS earliest_movie,
    MAX(m.production_year) AS latest_movie
FROM 
    aka_name akn
JOIN 
    cast_info cc ON akn.person_id = cc.person_id
JOIN 
    aka_title ttl ON cc.movie_id = ttl.movie_id
JOIN 
    role_type rt ON cc.role_id = rt.id
JOIN 
    movie_info mi ON cc.movie_id = mi.movie_id
JOIN 
    movie_keyword mk ON cc.movie_id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    title m ON cc.movie_id = m.id
JOIN 
    comp_cast_type ct ON cc.person_role_id = ct.id
JOIN 
    name p ON akn.person_id = p.imdb_id
WHERE 
    ttl.production_year BETWEEN 1990 AND 2023
GROUP BY 
    akn.name, ttl.title, p.name, ct.kind
ORDER BY 
    total_movies_by_person DESC, earliest_movie ASC;
