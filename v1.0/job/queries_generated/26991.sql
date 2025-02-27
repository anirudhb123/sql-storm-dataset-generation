WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name SEPARATOR ', ') AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS movie_keywords,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', ') AS company_names,
        COUNT(DISTINCT ci.person_id) AS total_cast_members,
        GROUP_CONCAT(DISTINCT rt.role ORDER BY rt.role SEPARATOR ', ') AS roles
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000 
    GROUP BY 
        mt.id, mt.title, mt.production_year
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    aka_names,
    movie_keywords,
    company_names,
    total_cast_members,
    roles
FROM 
    MovieDetails
WHERE 
    total_cast_members > 5
ORDER BY 
    production_year DESC, total_cast_members DESC;
