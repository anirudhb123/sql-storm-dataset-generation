WITH MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', ') AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
        GROUP_CONCAT(DISTINCT co.name ORDER BY co.name SEPARATOR ', ') AS companies,
        GROUP_CONCAT(DISTINCT p.name ORDER BY p.name SEPARATOR ', ') AS cast_members
    FROM
        aka_title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies AS mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_name AS co ON mc.company_id = co.id
    LEFT JOIN 
        complete_cast AS cc ON m.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    LEFT JOIN 
        name AS p ON ci.person_id = p.imdb_id
    GROUP BY 
        m.id, m.title, m.production_year
)
SELECT 
    movie_id,
    title,
    production_year,
    aka_names,
    keywords,
    companies,
    cast_members
FROM 
    MovieInfo
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, title;
