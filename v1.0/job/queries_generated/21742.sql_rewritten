WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 5
),
actor_info AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
),
name_count AS (
    SELECT 
        nk.name,
        COUNT(nk.id) AS count
    FROM 
        name nk
    GROUP BY 
        nk.name
)
SELECT 
    fm.title,
    fm.production_year,
    ai.name AS actor_name,
    ai.movie_count,
    nc.count AS name_count,
    COALESCE(nc.count, 0) AS name_count_or_zero,
    CASE 
        WHEN ai.movie_count > 10 THEN 'Prolific Actor'
        WHEN ai.movie_count BETWEEN 5 AND 10 THEN 'Experienced Actor'
        ELSE 'Newcomer Actor'
    END AS actor_category,
    STRING_AGG(DISTINCT km.keyword, ', ') AS keywords
FROM 
    filtered_movies fm
JOIN 
    cast_info ci ON fm.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    actor_info ai ON ak.person_id = ai.person_id
LEFT JOIN 
    movie_keyword mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    keyword km ON mk.keyword_id = km.id
LEFT JOIN 
    name_count nc ON ak.name = nc.name
WHERE 
    fm.production_year IS NOT NULL
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, ai.name, ai.movie_count, nc.count
HAVING 
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY 
    fm.production_year DESC, ai.movie_count DESC;