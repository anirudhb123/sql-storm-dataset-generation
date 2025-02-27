SELECT 
    st.title AS movie_title,
    ak.name AS actor_name,
    ct.kind AS role_type,
    t.production_year,
    cn.name AS company_name,
    ki.keyword AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title st ON ci.movie_id = st.id
JOIN 
    role_type ct ON ci.role_id = ct.id
JOIN 
    movie_companies mc ON st.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_keyword mk ON st.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    st.production_year >= 2000
ORDER BY 
    st.production_year DESC, ak.name;
