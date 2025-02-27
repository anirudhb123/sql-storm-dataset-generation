WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT an.name ORDER BY an.name) AS actor_names,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS company_names,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
    FROM 
        aka_title AS t
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name AS an ON ci.person_id = an.person_id
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_name AS c ON mc.company_id = c.id
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT an.name) > 5
)

SELECT 
    md.title,
    md.production_year,
    md.actor_names,
    md.company_names,
    md.keywords
FROM 
    MovieDetails AS md
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
