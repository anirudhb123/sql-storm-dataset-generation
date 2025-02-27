WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_info AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        ranked_movies t ON ci.movie_id = t.movie_id
    GROUP BY 
        a.person_id, a.name
),
company_stats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ai.movie_count,
        ai.movie_titles,
        cs.company_count,
        cs.company_names
    FROM 
        ranked_movies rm
    LEFT JOIN 
        actor_info ai ON rm.movie_id = ai.movie_count
    LEFT JOIN 
        company_stats cs ON rm.movie_id = cs.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.movie_count, 0) AS actor_count,
    COALESCE(md.company_count, 0) AS company_count,
    CASE 
        WHEN md.movie_count IS NULL THEN 'No Actors'
        ELSE md.movie_titles 
    END AS actor_titles,
    CASE 
        WHEN md.company_count IS NULL THEN 'No Companies'
        ELSE md.company_names 
    END AS listed_companies
FROM 
    movie_details md
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
