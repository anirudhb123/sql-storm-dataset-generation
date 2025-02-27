WITH ranked_movies AS (
    SELECT 
        at.title, 
        at.production_year, 
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
average_actor_count AS (
    SELECT 
        AVG(actor_count) AS avg_actor_count 
    FROM 
        ranked_movies
),
movies_with_actors AS (
    SELECT 
        at.title, 
        at.production_year, 
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
high_actor_movies AS (
    SELECT 
        mw.title, 
        mw.production_year 
    FROM 
        movies_with_actors mw
    JOIN 
        average_actor_count aac ON mw.actor_count > aac.avg_actor_count
),
detailed_movie_info AS (
    SELECT 
        mw.title,
        mw.production_year,
        mw.actor_count,
        COALESCE(mk.keyword, 'No Keywords') AS keywords,
        COALESCE(cn.name, 'Independent') AS company_name,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY mw.title) AS unique_cast_count,
        RANK() OVER (ORDER BY mw.actor_count DESC) AS actor_rank
    FROM 
        high_actor_movies mw
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = mw.title LIMIT 1)
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = mw.title LIMIT 1)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON (SELECT id FROM aka_title WHERE title = mw.title LIMIT 1) = ci.movie_id
)
SELECT 
    title, 
    production_year, 
    actor_count, 
    keywords, 
    company_name, 
    unique_cast_count, 
    actor_rank
FROM 
    detailed_movie_info
WHERE 
    actor_count IS NOT NULL
ORDER BY 
    production_year DESC, actor_rank
FETCH FIRST 10 ROWS ONLY;
