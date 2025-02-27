
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON a.person_id = c.person_id
    WHERE 
        t.production_year >= 2000
),
keyword_summary AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        movie_info m ON mk.movie_id = m.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id, 
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_name,
    rm.actor_rank,
    ks.keywords,
    ks.keyword_count,
    ci.companies,
    ci.company_count
FROM 
    ranked_movies rm
LEFT JOIN 
    keyword_summary ks ON rm.movie_id = ks.movie_id
LEFT JOIN 
    company_info ci ON rm.movie_id = ci.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.movie_id;
