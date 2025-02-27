WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        c.nr_order,
        pn.name AS person_name,
        kt.keyword AS movie_keyword,
        co.name AS company_name,
        ti.info AS movie_info
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id AND ci.person_id = cc.subject_id
    JOIN 
        aka_name pn ON pn.person_id = ci.person_id
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword kt ON kt.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name co ON co.id = mc.company_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = t.id
    LEFT JOIN 
        info_type ti ON ti.id = mi.info_type_id
    WHERE 
        t.production_year > 2000
        AND kt.keyword LIKE '%action%'
    ORDER BY 
        t.production_year DESC, wt.nr_order
)
SELECT 
    movie_title,
    person_name,
    keyword,
    company_name,
    movie_info
FROM 
    movie_data
WHERE 
    person_name IS NOT NULL
ORDER BY 
    movie_title;
