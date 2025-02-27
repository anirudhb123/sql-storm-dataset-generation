WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank,
        COUNT(ci.person_id) AS actor_count
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
popular_titles AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        CASE 
            WHEN rm.actor_count > 5 THEN 'High'
            WHEN rm.actor_count BETWEEN 3 AND 5 THEN 'Medium'
            ELSE 'Low' 
        END AS popularity
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank = 1
),
char_names AS (
    SELECT 
        cn.id AS char_id,
        cn.name AS character_name,
        ak.name AS actor_name
    FROM 
        char_name cn
    JOIN 
        aka_name ak ON ak.id = cn.imdb_id
    WHERE 
        ak.name IS NOT NULL
)
SELECT 
    pt.title,
    pt.production_year,
    pt.actor_count,
    pt.popularity,
    STRING_AGG(DISTINCT cn.character_name, ', ') AS character_names,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
FROM 
    popular_titles pt
LEFT JOIN 
    complete_cast cc ON pt.movie_id = cc.movie_id
LEFT JOIN 
    char_names cn ON cc.subject_id = cn.char_id
LEFT JOIN 
    aka_name ak ON ak.person_id = cc.subject_id
WHERE 
    pt.production_year IS NOT NULL
GROUP BY 
    pt.title, pt.production_year, pt.actor_count, pt.popularity
HAVING 
    COUNT(DISTINCT ak.name) >= 1 
ORDER BY 
    pt.production_year DESC, pt.actor_count DESC;
