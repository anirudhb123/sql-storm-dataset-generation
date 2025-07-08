
WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id) AS rank
    FROM title
    WHERE title.production_year IS NOT NULL
),
actor_appearance AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count,
        LISTAGG(an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS actors
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY ci.movie_id
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        aa.actor_count,
        aa.actors
    FROM ranked_movies rm
    LEFT JOIN actor_appearance aa ON rm.movie_id = aa.movie_id
    WHERE rm.rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.actor_count, 0) AS actor_count,
    CASE 
        WHEN tm.actor_count IS NULL THEN 'No actors found'
        ELSE tm.actors
    END AS actor_list,
    UPPER(tm.title) AS upper_title,
    (SELECT COUNT(DISTINCT mc.company_id) 
     FROM movie_companies mc 
     WHERE mc.movie_id = tm.movie_id) AS company_count,
    (SELECT COUNT(DISTINCT mk.keyword_id) 
     FROM movie_keyword mk 
     WHERE mk.movie_id = tm.movie_id) AS keyword_count
FROM top_movies tm
ORDER BY tm.production_year DESC, tm.title;
