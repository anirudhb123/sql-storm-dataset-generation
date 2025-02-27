WITH ranked_titles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        a.kind_id,
        a.imdb_index,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank
    FROM aka_title a
    JOIN movie_keyword mk ON a.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword ILIKE '%action%'
),
popular_actors AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM cast_info c
    JOIN ranked_titles rt ON c.movie_id = rt.title_id
    GROUP BY c.person_id
    HAVING COUNT(DISTINCT c.movie_id) > 3
),
actor_details AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        a.md5sum
    FROM aka_name a
    JOIN popular_actors pa ON a.person_id = pa.person_id
),
title_info AS (
    SELECT 
        rt.title,
        rt.production_year,
        k.keyword,
        COUNT(c.id) AS casting_count
    FROM ranked_titles rt
    JOIN cast_info c ON rt.title_id = c.movie_id
    JOIN movie_keyword mk ON rt.title_id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY rt.title, rt.production_year, k.keyword
    ORDER BY casting_count DESC
)
SELECT 
    ad.actor_id,
    ad.name AS actor_name,
    ti.title,
    ti.production_year,
    ti.keyword,
    ti.casting_count
FROM actor_details ad
JOIN title_info ti ON ad.actor_id = ti.title_id
WHERE ti.casting_count > 5
ORDER BY ti.production_year DESC, ti.casting_count DESC;
