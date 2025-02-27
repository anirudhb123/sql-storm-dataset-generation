WITH ranked_movies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
),

keyword_summary AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
),

company_summary AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rm.movie_title,
    rm.production_year,
    rm.actor_name,
    ks.keywords,
    cs.company_names
FROM 
    ranked_movies rm
LEFT JOIN 
    keyword_summary ks ON rm.movie_title = ks.movie_id
LEFT JOIN 
    company_summary cs ON rm.movie_title = cs.movie_id
WHERE 
    rm.actor_rank <= 3
ORDER BY 
    rm.production_year DESC, 
    rm.movie_title;
