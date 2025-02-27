WITH MovieDetails AS (
    SELECT 
        title.title AS movie_title,
        aka.title AS aka_title,
        company.name AS company_name,
        GROUP_CONCAT(DISTINCT keyword.keyword) AS keywords,
        ARRAY_AGG(DISTINCT name.name) AS cast_names,
        EXTRACT(YEAR FROM MIN(movie_info.info)) AS earliest_year,
        COUNT(*) AS cast_count
    FROM 
        aka_title AS aka
    JOIN 
        title ON aka.movie_id = title.id
    JOIN 
        movie_companies AS mc ON title.id = mc.movie_id
    JOIN 
        company_name AS company ON mc.company_id = company.id
    JOIN 
        complete_cast AS cc ON title.id = cc.movie_id
    JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name AS an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword AS mk ON title.id = mk.movie_id
    LEFT JOIN 
        keyword ON mk.keyword_id = keyword.id
    LEFT JOIN 
        movie_info AS movie_info ON title.id = movie_info.movie_id
    WHERE 
        title.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        title.id, aka.title, company.name
)
SELECT 
    movie_title,
    aka_title,
    company_name,
    keywords,
    cast_names,
    earliest_year,
    cast_count
FROM 
    MovieDetails
ORDER BY 
    earliest_year DESC, cast_count DESC
LIMIT 10;
