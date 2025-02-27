WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.id, t.title, t.production_year
),
high_cast_movies AS (
    SELECT 
        title_id,
        title,
        production_year,
        cast_count
    FROM ranked_movies
    WHERE cast_count > 5
),
movie_keyword_stats AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    hcm.title,
    hcm.production_year,
    hcm.cast_count,
    COALESCE(mks.keyword_count, 0) AS keyword_count,
    COALESCE(mks.keywords, 'No Keywords') AS keywords,
    COALESCE(aka.name, 'Unknown') AS aka_name,
    CASE
        WHEN mks.keyword_count IS NULL THEN 'No Keywords Associated'
        WHEN mks.keyword_count > 10 THEN 'Has Many Keywords'
        ELSE 'Few Keywords'
    END AS keyword_description
FROM high_cast_movies hcm
LEFT JOIN movie_keyword_stats mks ON hcm.title_id = mks.movie_id
LEFT JOIN aka_name aka ON aka.person_id IN (
        SELECT DISTINCT c.person_id 
        FROM cast_info c 
        WHERE c.movie_id = hcm.title_id
    )
ORDER BY hcm.production_year DESC, hcm.cast_count DESC
LIMIT 50;
