WITH MovieInfo AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        aka_title.title AS aka_movie_title,
        STRING_AGG(DISTINCT akn.name, ', ') AS aliases,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        MIN(mi.info) AS description
    FROM 
        title
    LEFT JOIN 
        aka_title ON title.id = aka_title.movie_id
    LEFT JOIN 
        movie_keyword AS mk ON title.id = mk.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_info AS mi ON title.id = mi.movie_id
    LEFT JOIN 
        movie_companies AS mc ON title.id = mc.movie_id
    LEFT JOIN 
        company_name AS cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info AS ci ON title.id = ci.movie_id
    LEFT JOIN 
        aka_name AS akn ON ci.person_id = akn.person_id
    GROUP BY 
        title.id, title.title, aka_title.title
)
SELECT 
    movie_id,
    movie_title,
    aka_movie_title,
    aliases,
    keywords,
    companies,
    description
FROM 
    MovieInfo
WHERE 
    production_year BETWEEN 2000 AND 2020
    AND movie_title ILIKE '%Action%'
ORDER BY 
    movie_title ASC;
