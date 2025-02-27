WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
),
company_details AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rk.actor_name,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    c.company_name,
    c.company_type,
    COUNT(DISTINCT rk.role_count) AS total_roles
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_details rk ON rm.movie_id = rk.movie_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    company_details c ON rm.movie_id = c.movie_id
WHERE 
    rm.title_rank <= 5
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, rk.actor_name, mk.keywords, c.company_name, c.company_type
ORDER BY 
    rm.production_year DESC, rm.title;
