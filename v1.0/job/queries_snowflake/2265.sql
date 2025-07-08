WITH MovieStats AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS cast_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
DirectorInfo AS (
    SELECT 
        ci.movie_id,
        pal.name AS director_name
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name pal ON ci.person_id = pal.person_id
    INNER JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        rt.role = 'director'
)
SELECT 
    ms.title,
    ms.production_year,
    ms.total_cast,
    di.director_name,
    ms.total_keywords,
    ms.cast_rank
FROM 
    MovieStats ms
LEFT JOIN 
    DirectorInfo di ON ms.movie_id = di.movie_id
WHERE 
    ms.production_year >= 2000
ORDER BY 
    ms.production_year DESC, ms.total_cast DESC
LIMIT 10;
