WITH top_keywords AS (
    SELECT movie_id, COUNT(keyword_id) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_id
    HAVING COUNT(keyword_id) > 3
),
movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        m.production_year,
        k.keyword,
        ak.name AS aka_name
    FROM title t
    JOIN movie_info mi ON t.id = mi.movie_id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN aka_title ak ON t.id = ak.movie_id
    JOIN top_keywords tk ON t.id = tk.movie_id
    WHERE mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
),
actor_info AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT p.name, ', ') AS actor_names
    FROM cast_info c
    JOIN aka_name p ON c.person_id = p.person_id
    GROUP BY c.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword,
    ai.actor_count,
    ai.actor_names,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = md.movie_id) AS company_count
FROM movie_details md
JOIN actor_info ai ON md.movie_id = ai.movie_id
ORDER BY md.production_year DESC, ai.actor_count DESC
LIMIT 10;
