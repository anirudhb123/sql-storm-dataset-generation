WITH movie_cast_info AS (
    SELECT 
        title.title AS movie_title,
        aka_name.name AS actor_name,
        role_type.role AS actor_role,
        title.production_year
    FROM 
        title
    JOIN 
        complete_cast ON title.id = complete_cast.movie_id
    JOIN 
        cast_info ON complete_cast.subject_id = cast_info.id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    JOIN 
        role_type ON cast_info.role_id = role_type.id
),
movie_keywords AS (
    SELECT 
        title.title AS movie_title,
        keyword.keyword AS movie_keyword
    FROM 
        title
    JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
)
SELECT 
    mci.movie_title,
    STRING_AGG(DISTINCT mci.actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT mci.actor_role, ', ') AS roles,
    STRING_AGG(DISTINCT mk.movie_keyword, ', ') AS keywords,
    mci.production_year
FROM 
    movie_cast_info mci
LEFT JOIN 
    movie_keywords mk ON mci.movie_title = mk.movie_title
GROUP BY 
    mci.movie_title, mci.production_year
ORDER BY 
    mci.production_year DESC;
