
WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        ak.name AS actor_name,
        p.gender AS actor_gender,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_name ak 
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mw ON t.id = mw.movie_id
    JOIN 
        keyword kw ON mw.keyword_id = kw.id
    JOIN 
        name p ON ak.person_id = p.imdb_id
    GROUP BY 
        t.title, t.production_year, c.name, ak.name, p.gender
),
highest_keyword_count AS (
    SELECT 
        movie_title,
        COUNT(*) AS keyword_count
    FROM 
        movie_data
    GROUP BY 
        movie_title
    ORDER BY 
        keyword_count DESC
    LIMIT 10
)
SELECT 
    md.movie_title,
    md.production_year,
    md.company_name,
    md.actor_name,
    md.actor_gender,
    hk.keyword_count,
    REPLACE(md.keywords, ', ', '|') AS keywords_formatted
FROM 
    movie_data md
JOIN 
    highest_keyword_count hk ON md.movie_title = hk.movie_title
ORDER BY 
    md.production_year DESC, 
    hk.keyword_count DESC;
