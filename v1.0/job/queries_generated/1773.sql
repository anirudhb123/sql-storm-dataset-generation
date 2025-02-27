WITH ranked_movies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
movies_with_keywords AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_title, rm.production_year, rm.actor_count
)
SELECT 
    mwk.movie_title,
    mwk.production_year,
    mwk.actor_count,
    mwk.keywords,
    CASE 
        WHEN mwk.actor_count IS NULL THEN 'No Actors'
        WHEN mwk.actor_count > 10 THEN 'Star Power'
        ELSE 'Regular Cast'
    END AS cast_description
FROM 
    movies_with_keywords mwk
WHERE 
    mwk.rank <= 5 OR mwk.actor_count IS NULL
ORDER BY 
    mwk.production_year DESC, mwk.actor_count DESC
FETCH FIRST 10 ROWS ONLY;
