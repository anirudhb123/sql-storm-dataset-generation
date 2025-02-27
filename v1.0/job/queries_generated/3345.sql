WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(CASE WHEN ci.role_id IS NOT NULL THEN 1 END) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.role_id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_title kt ON t.id = kt.movie_id
    WHERE 
        t.production_year IS NOT NULL 
        AND kt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'short'))
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies_per_year AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        ranked_movies
    WHERE 
        rn <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    a.name AS actor_name,
    kor.keyword AS movie_keyword,
    (
        SELECT COUNT(DISTINCT mc.company_id)
        FROM movie_companies mc
        WHERE mc.movie_id = tm.title_id
    ) AS company_count
FROM 
    top_movies_per_year tm
LEFT JOIN 
    cast_info ci ON tm.title_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON tm.title_id = mk.movie_id
LEFT JOIN 
    keyword kor ON mk.keyword_id = kor.id
WHERE 
    a.name IS NOT NULL 
    AND tm.production_year > 2000
ORDER BY 
    tm.production_year ASC, 
    num_cast DESC, 
    kor.keyword;
