WITH MovieDetails AS (
    SELECT 
        ak.title AS movie_title,
        ak.production_year,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS company_names,
        GROUP_CONCAT(DISTINCT KEY.keyword ORDER BY KEY.keyword SEPARATOR ', ') AS keywords,
        COUNT(DISTINCT c.person_id) AS number_of_actors,
        MAX(CASE WHEN ci.person_role_id IS NOT NULL THEN TRUE ELSE FALSE END) AS has_cast_info,
        GROUP_CONCAT(DISTINCT CONCAT(n.name, ' (', rt.role, ')') ORDER BY n.name SEPARATOR ', ') AS cast
    FROM 
        aka_title ak
    LEFT JOIN 
        movie_companies mc ON ak.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON ak.id = mk.movie_id
    LEFT JOIN 
        keyword KEY ON mk.keyword_id = KEY.id
    LEFT JOIN 
        complete_cast cc ON ak.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        role_type rt ON c.role_id = rt.id
    LEFT JOIN 
        aka_name n ON c.person_id = n.person_id
    GROUP BY 
        ak.id
)

SELECT 
    movie_title,
    production_year,
    company_names,
    keywords,
    number_of_actors,
    has_cast_info,
    cast
FROM 
    MovieDetails
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, number_of_actors DESC
LIMIT 100;
