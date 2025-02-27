WITH ranked_titles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
), filtered_titles AS (
    SELECT 
        actor_name, 
        movie_title, 
        production_year
    FROM ranked_titles
    WHERE rank <= 5
), title_keywords AS (
    SELECT 
        f.actor_name,
        f.movie_title,
        f.production_year,
        k.keyword
    FROM filtered_titles f
    LEFT JOIN movie_keyword mk ON f.movie_title = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
), name_info AS (
    SELECT 
        n.name,
        pi.info,
        pi.note
    FROM name n
    JOIN person_info pi ON n.imdb_id = pi.person_id
)
SELECT 
    ti.actor_name,
    ti.movie_title,
    ti.production_year,
    STRING_AGG(DISTINCT ti.keyword, ', ') AS keywords,
    ni.info,
    ni.note
FROM title_keywords ti
LEFT JOIN name_info ni ON ti.actor_name = ni.name
GROUP BY ti.actor_name, ti.movie_title, ti.production_year, ni.info, ni.note
ORDER BY ti.production_year DESC, ti.actor_name;
