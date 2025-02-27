WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        nt.name AS title_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        name nt ON t.id = nt.imdb_id
    WHERE 
        t.production_year IS NOT NULL
), 
cast_summary AS (
    SELECT 
        cm.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        complete_cast cm
    JOIN 
        cast_info ci ON cm.movie_id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        cm.movie_id
), 
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
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
    cs.total_cast,
    cs.actor_names,
    mk.keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_summary cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
WHERE 
    (cs.total_cast IS NULL OR cs.total_cast > 5)
    AND rm.rn <= 10
ORDER BY 
    rm.production_year DESC,
    rm.title;
