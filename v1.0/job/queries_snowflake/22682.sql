
WITH ranked_movies AS (
    SELECT 
        a.id AS aka_id,
        a.name,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE t.production_year IS NOT NULL
),
genre_count AS (
    SELECT 
        t.id AS title_id,
        COUNT(DISTINCT km.keyword) AS genre_count
    FROM aka_title t
    LEFT JOIN movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN keyword km ON mk.keyword_id = km.id
    GROUP BY t.id
),
company_stats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS company_names
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY mc.movie_id
) 
SELECT 
    rm.name AS actor_name,
    rm.title,
    rm.production_year,
    gc.genre_count,
    cs.company_count,
    cs.company_names,
    COALESCE(cs.company_count, 0) AS non_null_company_count
FROM ranked_movies rm
LEFT JOIN genre_count gc ON rm.aka_id = gc.title_id
LEFT JOIN company_stats cs ON rm.aka_id = cs.movie_id
WHERE rm.rank = 1 
  AND (gc.genre_count IS NULL OR gc.genre_count > 3)
ORDER BY rm.production_year DESC,
         rm.name ASC,
         gc.genre_count DESC;
