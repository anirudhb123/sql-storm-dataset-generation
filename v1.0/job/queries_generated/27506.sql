WITH movie_details AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year, 
        ak.title AS ak_title,
        ak.kind_id,
        GROUP_CONCAT(DISTINCT CONCAT_WS(' ', cn.name, ct.kind) ORDER BY cn.name) AS companies,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT CONCAT_WS(': ', rt.role, COALESCE(pn.name, 'Unknown'))) AS roles
    FROM 
        aka_title ak
    JOIN 
        title mt ON ak.movie_id = mt.id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        aka_name pn ON ci.person_id = pn.person_id
    WHERE 
        ak.production_year >= 2000
    GROUP BY 
        mt.id, ak.title, mt.production_year, ak.kind_id
)
SELECT 
    movie_id, 
    movie_title, 
    production_year, 
    companies, 
    keywords, 
    roles 
FROM 
    movie_details
WHERE 
    companies IS NOT NULL AND
    keywords IS NOT NULL
ORDER BY 
    production_year DESC, 
    movie_title ASC;
