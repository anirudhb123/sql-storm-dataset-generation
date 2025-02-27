WITH ranked_titles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),

recent_movies AS (
    SELECT 
        actor_name,
        movie_title,
        production_year
    FROM ranked_titles
    WHERE rn = 1
),

keyword_counts AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    JOIN aka_title m ON mk.movie_id = m.id
    GROUP BY m.movie_id
),

actor_movie_details AS (
    SELECT 
        r.actor_name,
        r.movie_title,
        r.production_year,
        kc.keyword_count
    FROM recent_movies r
    LEFT JOIN keyword_counts kc ON r.movie_title = kc.movie_id
)

SELECT 
    amd.actor_name,
    amd.movie_title,
    amd.production_year,
    COALESCE(amd.keyword_count, 0) AS keyword_count,
    ak.name_pcode_cf,
    ak.name_pcode_nf
FROM actor_movie_details amd
JOIN aka_name ak ON ak.name = amd.actor_name
ORDER BY amd.production_year DESC, amd.keyword_count DESC;
