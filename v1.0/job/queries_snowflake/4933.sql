
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
company_movie_counts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    WHERE 
        mc.company_id IS NOT NULL
    GROUP BY 
        mc.movie_id
),
keyword_aggregation AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(cmc.company_count, 0) AS company_count,
    COALESCE(ka.keywords, 'No keywords') AS keywords,
    (SELECT COUNT(DISTINCT ci.person_id)
     FROM cast_info ci
     WHERE ci.movie_id = rm.movie_id AND ci.note IS NULL) AS casting_without_note
FROM 
    ranked_movies rm
LEFT JOIN 
    company_movie_counts cmc ON rm.movie_id = cmc.movie_id
LEFT JOIN 
    keyword_aggregation ka ON rm.movie_id = ka.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.title;
