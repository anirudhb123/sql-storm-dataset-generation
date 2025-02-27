WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, t.title, t.production_year, COALESCE(c.kind, 'Unknown') AS company_kind
    FROM aka_title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_type c ON mc.company_type_id = c.id
    WHERE t.production_year >= 2000
    
    UNION ALL
    
    SELECT mh.movie_id, mh.title, mh.production_year, mh.company_kind
    FROM movie_hierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title t ON ml.linked_movie_id = t.id
    WHERE t.production_year >= 2000
),
top_movies AS (
    SELECT m.title, COUNT(DISTINCT c.person_id) AS actor_count
    FROM aka_title m
    JOIN cast_info c ON m.id = c.movie_id
    WHERE m.production_year = (
        SELECT MAX(production_year) FROM aka_title
    )
    GROUP BY m.title
    HAVING COUNT(DISTINCT c.person_id) > 5
),
movie_keywords AS (
    SELECT m.id AS movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM aka_title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id
    HAVING COUNT(mk.keyword_id) > 2
)
SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    mh.company_kind AS Company_Kind,
    tk.actor_count AS Actor_Count,
    COALESCE(k.keywords, 'No Keywords') AS Keywords
FROM movie_hierarchy mh
LEFT JOIN top_movies tk ON mh.title = tk.title
LEFT JOIN movie_keywords k ON mh.movie_id = k.movie_id
WHERE mh.company_kind IS NOT NULL
ORDER BY mh.production_year DESC, tk.actor_count DESC;
