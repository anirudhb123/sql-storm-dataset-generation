WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_by_year
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
        COUNT(ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(cd.actors, 'No Actors') AS actors
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    cast_details cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.rank_by_year <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title;
