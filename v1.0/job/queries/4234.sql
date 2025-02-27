WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title AS t
    WHERE 
        t.production_year IS NOT NULL
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
cast_details AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(CASE WHEN r.role = 'lead' THEN 1 ELSE 0 END) AS has_lead
    FROM 
        cast_info AS c
    JOIN 
        role_type AS r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    r.title AS Movie_Title,
    r.production_year AS Production_Year,
    COALESCE(mk.keywords, 'No Keywords') AS Keywords,
    cd.actor_count AS Actor_Count,
    CASE 
        WHEN cd.has_lead = 1 THEN 'Yes' 
        ELSE 'No' 
    END AS Has_Lead_Role
FROM 
    ranked_movies AS r
LEFT JOIN 
    movie_keywords AS mk ON r.title_id = mk.movie_id
LEFT JOIN 
    cast_details AS cd ON r.title_id = cd.movie_id
WHERE 
    r.title_rank <= 5
ORDER BY 
    r.production_year DESC, 
    r.title ASC;
