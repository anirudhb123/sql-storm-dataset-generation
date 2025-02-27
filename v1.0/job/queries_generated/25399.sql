WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mk.keyword_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),

top_keywords AS (
    SELECT 
        kt.keyword,
        COUNT(DISTINCT t.id) AS movie_count
    FROM 
        keyword kt
    JOIN 
        movie_keyword mk ON mk.keyword_id = kt.id
    JOIN 
        aka_title t ON t.movie_id = mk.movie_id
    WHERE 
        kt.phonetic_code IS NOT NULL
    GROUP BY 
        kt.keyword
    ORDER BY 
        movie_count DESC
    LIMIT 10
),

actor_roles AS (
    SELECT 
        ak.name AS actor_name,
        rt.role AS role,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    JOIN 
        role_type rt ON rt.id = ci.role_id
    WHERE 
        ak.name_pcode_cf IN (SELECT DISTINCT name_pcode_cf FROM company_name)
    GROUP BY 
        ak.name, rt.role
)

SELECT 
    rt.title AS movie_title,
    rt.production_year,
    tk.keyword AS popular_keyword,
    ar.actor_name,
    ar.role,
    ar.movie_count
FROM 
    ranked_titles rt
JOIN 
    top_keywords tk ON tk.movie_count > 5  -- Join titles that have more than 5 popular keywords
JOIN 
    actor_roles ar ON ar.movie_count > 10   -- Join actors who have played in more than 10 movies
WHERE 
    rt.rank <= 5                             -- Select top 5 titles per production year
ORDER BY 
    rt.production_year ASC, rt.rank, ar.movie_count DESC;
