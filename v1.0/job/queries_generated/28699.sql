WITH ranked_titles AS (
    SELECT 
        at.title,
        at.production_year,
        ak.name AS actor_name,
        rk.rank AS title_rank,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year >= 2000
),
movie_keywords AS (
    SELECT 
        mt.movie_id,
        GROUP_CONCAT(mk.keyword) AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword mk ON mt.keyword_id = mk.id
    GROUP BY 
        mt.movie_id
),
movies_with_keywords AS (
    SELECT 
        rt.title,
        rt.production_year,
        rk.actor_name,
        rk.title_rank,
        mk.keywords
    FROM 
        ranked_titles rt
    LEFT JOIN 
        movie_keywords mk ON rt.id = mk.movie_id
)
SELECT
    mwk.title,
    mwk.production_year,
    mwk.actor_name,
    mwk.title_rank,
    mwk.keywords
FROM 
    movies_with_keywords mwk
WHERE 
    mwk.keywords LIKE '%action%'
ORDER BY 
    mwk.title_rank, mwk.production_year DESC;
