SELECT 
    akn.name AS actor_name,
    ttl.title AS movie_title,
    ttl.production_year,
    grp_comp.name AS company_name,
    k.keyword AS movie_keyword,
    pt.info AS person_info
FROM 
    aka_name akn
JOIN 
    cast_info ci ON akn.person_id = ci.person_id
JOIN 
    title ttl ON ci.movie_id = ttl.id
LEFT JOIN 
    movie_companies mc ON ttl.id = mc.movie_id
LEFT JOIN 
    company_name grp_comp ON mc.company_id = grp_comp.id
LEFT JOIN 
    movie_keyword mk ON ttl.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pt ON akn.person_id = pt.person_id AND pt.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Biography'
    )
WHERE 
    ttl.production_year > 2000
    AND akn.name IS NOT NULL
    AND ttl.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
ORDER BY 
    ttl.production_year DESC, akn.name;
