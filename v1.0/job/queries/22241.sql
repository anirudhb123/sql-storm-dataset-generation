WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        c.movie_id,
        c.person_id,
        coalesce(a.name, cn.name, '') AS actor_name,
        r.role,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS cast_count
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        char_name cn ON c.person_id = cn.imdb_id
    INNER JOIN 
        role_type r ON c.role_id = r.id
),
company_movies AS (
    SELECT 
        mc.movie_id,
        string_agg(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        string_agg(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title AS Movie_Title,
    rt.production_year AS Production_Year,
    cd.actor_name AS Cast,
    cd.cast_count AS Number_of_Actors,
    cm.company_names AS Production_Companies,
    mk.keywords AS Movie_Keywords
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_details cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    company_movies cm ON rt.title_id = cm.movie_id
LEFT JOIN 
    movie_keywords mk ON rt.title_id = mk.movie_id
WHERE 
    rt.title_rank = 1                
    AND rt.production_year > 1980    
    AND (cd.actor_name IS NOT NULL OR cd.cast_count IS NULL)  
ORDER BY 
    rt.production_year DESC,
    rt.title ASC;