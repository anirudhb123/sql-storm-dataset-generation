SELECT 
    t.title AS movie_title,
    c.name AS actor_name,
    r.role AS actor_role,
    k.keyword AS movie_keyword,
    mci.note AS company_note,
    COUNT(DISTINCT mi.info) AS info_count,
    STRING_AGG(DISTINCT ci.note, ', ') AS cast_notes,
    MAX(tv.production_year) AS latest_production_year
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name c ON ci.person_id = c.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mci ON t.id = mci.movie_id
JOIN 
    company_name cn ON mci.company_id = cn.id
GROUP BY 
    t.title, c.name, r.role, k.keyword, mci.note
HAVING 
    COUNT(DISTINCT mi.info) > 1
ORDER BY 
    latest_production_year DESC, movie_title;
