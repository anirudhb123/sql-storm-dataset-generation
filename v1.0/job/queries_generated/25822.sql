WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),

extended_cast AS (
    SELECT 
        ci.movie_id,
        p.info AS person_info,
        r.role AS role_info,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        name p ON ci.person_id = p.id
    JOIN 
        role_type r ON ci.role_id = r.id
),

company_details AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)

SELECT 
    rm.title,
    rm.production_year,
    LISTAGG(rm.keyword, ', ') AS keywords,
    LISTAGG(ec.person_info || ' (' || ec.role_info || ')', '; ') AS cast_details,
    LISTAGG(cd.company_name || ' (' || cd.company_type || ')', '; ') AS production_companies
FROM 
    ranked_movies rm
LEFT JOIN 
    extended_cast ec ON rm.movie_id = ec.movie_id
LEFT JOIN 
    company_details cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.keyword_rank <= 5 -- Limit to top 5 keywords
    AND ec.role_rank <= 3 -- Limit to top 3 cast roles for each movie
GROUP BY 
    rm.movie_id, rm.title, rm.production_year
ORDER BY 
    rm.production_year DESC, rm.title;
