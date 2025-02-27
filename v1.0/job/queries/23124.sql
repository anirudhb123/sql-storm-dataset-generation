WITH RECURSIVE top_movies AS (
    SELECT t.id, t.title, t.production_year
    FROM aka_title t
    JOIN movie_info mi ON t.id = mi.movie_id
    WHERE mi.info_type_id = (SELECT id FROM info_type WHERE info = 'genre') 
      AND mi.info LIKE '%Action%'
    ORDER BY t.production_year DESC
    LIMIT 10
),
ranked_cast AS (
    SELECT 
        c.id,
        c.person_id,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) as role_rank,
        r.role
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    WHERE c.note IS NULL 
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mk.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.phonetic_code IS NOT NULL
),
complex_joins AS (
    SELECT 
        t.title,
        ak.name AS actor_name,
        mc.note AS company_note,
        mi.info AS movie_info,
        mk.keyword
    FROM top_movies t
    LEFT JOIN ranked_cast c ON t.id = c.movie_id
    LEFT JOIN aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
    LEFT JOIN movie_keywords mk ON t.id = mk.movie_id
)
SELECT 
    title,
    actor_name,
    company_note,
    movie_info,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords
FROM complex_joins
WHERE actor_name IS NOT NULL
GROUP BY title, actor_name, company_note, movie_info
HAVING COUNT(DISTINCT keyword) > 2 
ORDER BY title, actor_name;