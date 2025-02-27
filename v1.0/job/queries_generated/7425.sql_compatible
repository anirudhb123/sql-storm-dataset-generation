
WITH RecursiveCTE AS (
    SELECT 
        a.id AS aka_name_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title AS title,
        c.movie_id,
        c.person_id,
        p.info AS person_info,
        k.keyword AS movie_keyword,
        ct.kind AS company_type,
        ci.kind AS cast_type
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        person_info p ON a.person_id = p.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        comp_cast_type ci ON c.person_role_id = ci.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
        AND p.info_type_id = 1
    ORDER BY 
        t.production_year DESC
)
SELECT 
    aka_name_id,
    aka_name,
    title_id,
    title,
    movie_id,
    person_id,
    person_info,
    movie_keyword,
    company_type,
    cast_type
FROM 
    RecursiveCTE
WHERE 
    movie_keyword IN (SELECT keyword FROM keyword WHERE id < 100)
ORDER BY 
    aka_name ASC, title ASC;
