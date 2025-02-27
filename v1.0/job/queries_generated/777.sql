WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_count AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci 
    GROUP BY 
        ci.person_id
),
filtered_movies AS (
    SELECT DISTINCT 
        m.id AS movie_id,
        m.title,
        COALESCE(mk.keyword, 'N/A') AS keyword
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year >= 2000
),
actor_details AS (
    SELECT 
        ak.name AS actor_name,
        ac.movie_id,
        rt.title_id,
        rt.title,
        rt.production_year,
        COALESCE(ac.note, 'No Role') AS role_note
    FROM 
        aka_name ak
    JOIN 
        cast_info ac ON ak.person_id = ac.person_id
    JOIN 
        filtered_movies fm ON ac.movie_id = fm.movie_id
    JOIN 
        ranked_titles rt ON fm.movie_id = rt.title_id
    WHERE 
        ak.name IS NOT NULL
)
SELECT 
    ad.actor_name,
    ad.title,
    ad.production_year,
    ad.role_note,
    COALESCE(AMC.movie_count, 0) AS total_movies,
    CASE 
        WHEN AMC.movie_count > 5 THEN 'Veteran Actor'
        WHEN AMC.movie_count BETWEEN 2 AND 5 THEN 'Experienced Actor'
        ELSE 'Newcomer'
    END AS actor_experience
FROM 
    actor_details ad
LEFT JOIN 
    actor_movie_count AMC ON ad.actor_name = AMC.person_id
ORDER BY 
    ad.production_year DESC, ad.actor_name;
