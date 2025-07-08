
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS actor_rank,
        COUNT(ci.person_id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_rated_movies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        ranked_movies
    WHERE 
        actor_rank = 1
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cn.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
final_results AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(k.keywords, 'No Keywords') AS keywords,
        COALESCE(c.company_name, 'Unknown Company') AS company_name,
        COALESCE(c.company_type, 'Unknown Type') AS company_type,
        COUNT(ci.person_id) AS actor_count
    FROM 
        top_rated_movies t
    LEFT JOIN 
        movie_keywords k ON t.movie_id = k.movie_id
    LEFT JOIN 
        company_info c ON t.movie_id = c.movie_id AND c.company_rank = 1
    LEFT JOIN 
        complete_cast cc ON t.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.title, t.production_year, k.keywords, c.company_name, c.company_type
)
SELECT 
    *,
    CASE 
        WHEN production_year IS NULL THEN 'Year Unknown'
        WHEN actor_count > 10 THEN 'Ensemble Cast'
        ELSE 'Regular Cast'
    END AS cast_description
FROM 
    final_results
WHERE 
    production_year IS NOT NULL
ORDER BY 
    production_year DESC, title
LIMIT 50;
