
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ct.kind AS company_type,
        STRING_AGG(CONCAT_WS(', ', ak.name, n.name), ', ') AS cast_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        company_type ct ON ct.id = mc.company_type_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    LEFT JOIN 
        person_info pi ON pi.person_id = ak.person_id
    LEFT JOIN 
        name n ON n.id = pi.person_id
    WHERE 
        t.production_year >= 2000 AND 
        ct.kind = 'Distributor'
    GROUP BY 
        t.id, t.title, t.production_year, ct.kind
    ORDER BY 
        t.production_year DESC
)
SELECT 
    movie_title, 
    production_year, 
    company_type, 
    cast_names, 
    keywords
FROM 
    MovieDetails
WHERE 
    cast_names IS NOT NULL
LIMIT 10;
