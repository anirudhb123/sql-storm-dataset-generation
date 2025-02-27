WITH ranked_titles AS (
    SELECT 
        title.id AS title_id,
        title.title AS movie_title,
        title.production_year,
        aka_name.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY title.id ORDER BY aka_name.name) AS actor_rank
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        title.production_year >= 2000
), keyword_summary AS (
    SELECT 
        movie_keyword.movie_id,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_keyword.movie_id
), movie_details AS (
    SELECT 
        r.title_id,
        r.movie_title,
        r.production_year,
        r.actor_name,
        r.actor_rank,
        k.keywords
    FROM 
        ranked_titles r
    LEFT JOIN 
        keyword_summary k ON r.title_id = k.movie_id
)

SELECT 
    md.movie_title,
    md.production_year,
    STRING_AGG(md.actor_name, ', ' ORDER BY md.actor_rank) AS cast,
    md.keywords
FROM 
    movie_details md
WHERE 
    md.actor_rank <= 3 -- Limiting to first 3 actors
GROUP BY 
    md.movie_title, md.production_year, md.keywords
ORDER BY 
    md.production_year DESC, md.movie_title;
