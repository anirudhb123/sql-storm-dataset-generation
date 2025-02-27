WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        COALESCE(CAST(mt.note AS text), 'N/A') AS movie_note,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        role_type rt ON c.role_id = rt.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        (t.kind_id IN (1, 2) OR t.production_year > 2000)
        AND (it.info LIKE '%Oscar%' OR COALESCE(rt.role, '') != '')
    GROUP BY 
        t.id, t.title, mt.note
),
top_movies AS (
    SELECT 
        movie_id, 
        title, 
        movie_note 
    FROM 
        ranked_movies 
    WHERE 
        rn <= 5
)

SELECT 
    tm.title, 
    COALESCE(CAST(ak.name AS text), 'Unknown Actor') AS actor_name,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') FILTER (WHERE mk.keyword IS NOT NULL) AS keywords,
    AVG(mi.info::integer) FILTER (WHERE mi.info_type_id = 1) AS average_rating
FROM 
    top_movies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
GROUP BY 
    tm.movie_id, tm.title, ak.name
HAVING 
    COUNT(DISTINCT c.id) > 2 
ORDER BY 
    average_rating DESC, keyword_count DESC;
