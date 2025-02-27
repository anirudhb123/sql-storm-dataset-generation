WITH movie_titles AS (
    SELECT 
        t.title,
        t.production_year,
        rt.role,
        ak.name AS actor_name,
        COALESCE(COUNT(mk.keyword_id), 0) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.title, t.production_year, rt.role, ak.name
),
ranked_movies AS (
    SELECT 
        title,
        production_year,
        role,
        actor_name,
        keyword_count,
        RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank_with_keyword
    FROM 
        movie_titles 
),
filtered_movies AS (
    SELECT 
        title,
        production_year,
        role,
        actor_name,
        keyword_count,
        rank_with_keyword
    FROM 
        ranked_movies
    WHERE 
        rank_with_keyword <= 5
)
SELECT 
    fm.title,
    fm.production_year,
    fm.role,
    fm.actor_name,
    fm.keyword_count,
    (SELECT COUNT(DISTINCT ci.movie_id) 
     FROM cast_info ci 
     WHERE ci.person_id IN (SELECT ak.person_id FROM aka_name ak WHERE ak.name = fm.actor_name)) AS actor_movie_count,
    CASE 
        WHEN fm.keyword_count IS NULL THEN 'No Keywords'
        ELSE 'Has Keywords'
    END AS keyword_presence
FROM 
    filtered_movies fm
ORDER BY 
    fm.production_year DESC, fm.keyword_count DESC;
