WITH film_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        r.role AS role_name,
        c.note AS cast_note,
        co.name AS company_name,
        ct.kind AS company_type,
        m.info AS movie_info
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
    WHERE 
        t.production_year >= 2000
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    role_name,
    cast_note,
    company_name,
    company_type,
    movie_info
FROM 
    film_details
ORDER BY 
    production_year DESC, movie_title;
