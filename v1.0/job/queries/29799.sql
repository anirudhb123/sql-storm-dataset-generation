
WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ARRAY_AGG(DISTINCT actor.name) AS actors,
        COUNT(DISTINCT keyword.keyword) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT keyword.keyword) DESC) AS rank
    FROM 
        title
    JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name AS actor ON cast_info.person_id = actor.person_id
    GROUP BY 
        title.id, title.title, title.production_year
),
filtered_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actors,
        keyword_count
    FROM 
        ranked_movies
    WHERE 
        keyword_count > 5
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.actors,
    fm.keyword_count,
    cp.kind AS comp_type
FROM 
    filtered_movies fm
JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
JOIN 
    company_type cp ON mc.company_type_id = cp.id
WHERE 
    cp.kind ILIKE '%production%'
ORDER BY 
    fm.keyword_count DESC, fm.production_year DESC;
