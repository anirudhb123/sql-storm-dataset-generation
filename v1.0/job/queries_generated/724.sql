WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM title t
    WHERE t.production_year IS NOT NULL
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.movie_id
),
movie_keyword_summary AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        MAX(COALESCE(mk.note, 'No Note')) AS latest_note
    FROM movie_keyword mk
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cs.total_cast,
    cs.cast_names,
    mks.keyword_count,
    mks.latest_note
FROM ranked_movies rm
LEFT JOIN cast_summary cs ON rm.title_id = cs.movie_id
LEFT JOIN movie_keyword_summary mks ON rm.title_id = mks.movie_id
WHERE rm.rank_per_year <= 5
ORDER BY rm.production_year DESC, rm.title ASC;
