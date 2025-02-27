WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
movies_with_keywords AS (
    SELECT 
        mv.title,
        mv.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        ranked_movies mv
    LEFT JOIN 
        movie_keyword mk ON mv.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mv.title, mv.production_year
),
distinct_actors AS (
    SELECT 
        DISTINCT a.name 
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        a.name IS NOT NULL
),
latest_movies AS (
    SELECT 
        title, 
        production_year
    FROM 
        ranked_movies 
    WHERE 
        rank_within_year = 1
)
SELECT 
    lm.title,
    lm.production_year,
    mw.keywords,
    d.name AS distinct_actor_name
FROM 
    latest_movies lm
LEFT JOIN 
    movies_with_keywords mw ON lm.title = mw.title
LEFT JOIN 
    distinct_actors d ON d.name IS NOT NULL
WHERE 
    lm.production_year > 2000
ORDER BY 
    lm.production_year DESC, lm.title;
