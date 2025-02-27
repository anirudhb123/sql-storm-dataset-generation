WITH ranked_titles AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_titles AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.company_count,
        rt.keyword_count
    FROM 
        ranked_titles rt
    WHERE 
        rt.rank <= 5
),
person_movie_roles AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        t.title,
        rt.production_year,
        rt.company_count,
        rt.keyword_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        top_titles rt ON t.title = rt.title AND t.production_year = rt.production_year
)
SELECT 
    p.movie_count,
    p.actor_name,
    p.title,
    p.production_year,
    p.company_count,
    p.keyword_count
FROM 
    (SELECT 
        actor_name,
        title,
        production_year,
        company_count,
        keyword_count,
        COUNT(title) OVER (PARTITION BY actor_name) AS movie_count
     FROM 
        person_movie_roles) p
ORDER BY 
    p.movie_count DESC, 
    p.keyword_count DESC;
