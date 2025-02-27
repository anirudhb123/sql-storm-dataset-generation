
WITH ranked_movies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        STRING_AGG(a.name, ', ') AS cast_names,
        t.id AS movie_id
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
    ORDER BY 
        t.production_year DESC
    LIMIT 50
),
ranked_companies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.movie_keyword,
    rm.cast_names,
    rc.company_name,
    rc.company_type
FROM 
    ranked_movies rm
LEFT JOIN 
    ranked_companies rc ON rm.movie_id = rc.movie_id
ORDER BY 
    rm.production_year DESC, rm.movie_title;
