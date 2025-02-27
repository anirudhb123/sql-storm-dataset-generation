WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM title t
    WHERE t.title IS NOT NULL
), 
actors AS (
    SELECT 
        a.person_id,
        a.name,
        c.movie_id,
        r.role,
        COALESCE(c.nr_order, 0) AS order_position
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    LEFT JOIN role_type r ON c.role_id = r.id
), 
movie_info_ext AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT i.info_type_id) AS info_count,
        STRING_AGG(i.info, '; ') AS info_summary,
        COALESCE(MAX(i.info), 'No info available') AS latest_info
    FROM movie_info m
    JOIN movie_info i ON m.movie_id = i.movie_id
    GROUP BY m.movie_id
),
key_word_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.rank,
    rm.total_movies,
    a.name AS actor_name,
    COALESCE(ki.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN a.order_position = 1 THEN 'Lead Actor'
        WHEN a.order_position < 4 THEN 'Supporting Actor'
        ELSE 'Minor Role'
    END AS role_description,
    m.info_count,
    m.latest_info
FROM ranked_movies rm
LEFT JOIN actors a ON rm.movie_id = a.movie_id
LEFT JOIN key_word_summary ki ON rm.movie_id = ki.movie_id
LEFT JOIN movie_info_ext m ON rm.movie_id = m.movie_id
WHERE (rm.production_year IS NOT NULL AND rm.production_year >= 2000)
  AND (a.name IS NOT NULL AND a.name <> 'UNKNOWN')
ORDER BY rm.production_year DESC, rm.rank;
