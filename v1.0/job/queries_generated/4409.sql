WITH ranked_movies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tvSeries'))
    GROUP BY 
        t.id, t.title, t.production_year
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        ARRAY_AGG(DISTINCT rt.role) AS roles,
        COUNT(DISTINCT ci.person_id) AS unique_actors
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
popular_keywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(mk.keyword_id) > 3
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    cr.roles,
    CASE 
        WHEN cr.unique_actors IS NULL THEN 'No Actors' 
        ELSE cr.unique_actors 
    END AS actor_count,
    COALESCE(pk.keyword, 'No Popular Keywords') AS popular_keyword
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_roles cr ON rm.movie_title = (SELECT title FROM aka_title WHERE id = cr.movie_id)
LEFT JOIN 
    popular_keywords pk ON rm.production_year = (SELECT production_year FROM aka_title WHERE id = pk.movie_id)
WHERE 
    rm.rank_by_cast <= 10
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
