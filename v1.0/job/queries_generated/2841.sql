WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_info AS (
    SELECT 
        a.name,
        a.person_id,
        a.md5sum,
        r.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_name a
    JOIN 
        cast_info r ON a.person_id = r.person_id
    LEFT JOIN 
        movie_keyword k ON r.movie_id = k.movie_id
    GROUP BY 
        a.name, a.person_id, a.md5sum, r.movie_id
),
movies_with_keywords AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(ak.actor_count, 0) AS actor_count,
        COALESCE(api.keyword_count, 0) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        ranked_movies ak ON t.title = ak.title AND t.production_year = ak.production_year
    LEFT JOIN 
        actor_info api ON t.id = api.movie_id
)
SELECT 
    mw.title,
    mw.production_year,
    mw.actor_count,
    mw.keyword_count,
    COALESCE(mw.actor_count, 0) + COALESCE(mw.keyword_count, 0) AS total_score
FROM 
    movies_with_keywords mw
WHERE 
    mw.actor_count > 0 OR mw.keyword_count > 0
ORDER BY 
    total_score DESC, mw.production_year DESC
LIMIT 10;
