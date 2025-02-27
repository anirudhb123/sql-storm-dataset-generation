WITH movie_rankings AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(aka.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN cast_info c ON t.id = c.movie_id
    LEFT JOIN aka_name aka ON c.person_id = aka.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    WHERE t.production_year >= 2000
    GROUP BY t.id
),
ranked_movies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM movie_rankings
)
SELECT 
    rm.rank,
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.actors,
    rm.keywords 
FROM ranked_movies rm
WHERE rm.rank <= 10
ORDER BY rm.rank;
