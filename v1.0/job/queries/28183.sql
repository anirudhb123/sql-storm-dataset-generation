
WITH ranked_movies AS (
    SELECT 
        t.title AS movie_title, 
        t.production_year, 
        a.name AS actor_name, 
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
),
keyword_stats AS (
    SELECT 
        mk.movie_id, 
        COUNT(DISTINCT k.keyword) AS keyword_count,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movies_with_keywords AS (
    SELECT 
        rm.movie_title, 
        rm.production_year, 
        rm.actor_name, 
        rm.actor_rank, 
        ks.keyword_count, 
        ks.keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        keyword_stats ks ON rm.movie_title = (SELECT title FROM title WHERE id = ks.movie_id)
)
SELECT 
    mwk.movie_title,
    mwk.production_year,
    mwk.actor_name,
    mwk.actor_rank,
    COALESCE(mwk.keyword_count, 0) AS total_keywords,
    COALESCE(mwk.keywords, 'No keywords') AS keyword_list
FROM 
    movies_with_keywords mwk
WHERE 
    mwk.actor_rank = 1
ORDER BY 
    mwk.production_year DESC, 
    mwk.movie_title;
