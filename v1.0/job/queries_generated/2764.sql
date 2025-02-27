WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS actor_count_rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
most_popular_movies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year
    FROM 
        ranked_movies r
    WHERE 
        r.actor_count_rank = 1
),
movie_details AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(GROUP_CONCAT(DISTINCT kw.keyword), 'No Tags') AS keywords,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM 
        most_popular_movies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    GROUP BY 
        m.movie_id
),
actor_info AS (
    SELECT 
        DISTINCT ci.movie_id,
        ak.name AS actor_name,
        'Actor' AS role
    FROM 
        cast_info ci 
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.production_companies,
    CAST(ai.actor_name AS VARCHAR) AS actor_name,
    RANK() OVER (PARTITION BY md.movie_id ORDER BY ai.actor_name) AS actor_rank
FROM 
    movie_details md
LEFT JOIN 
    actor_info ai ON md.movie_id = ai.movie_id
WHERE 
    md.production_companies > 0
ORDER BY 
    md.production_year DESC, md.title ASC, actor_rank ASC;
