WITH filtered_titles AS (
    SELECT
        a.id AS title_id,
        a.title,
        a.production_year,
        k.keyword AS title_keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.id) AS year_rank
    FROM aka_title a
    LEFT JOIN movie_keyword mk ON a.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE a.production_year IS NOT NULL AND a.production_year > 2000
),
actor_info AS (
    SELECT
        c.id AS cast_id,
        p.person_id,
        a.name AS actor_name,
        COALESCE(m.note, 'No role specified') AS role_note,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS order_rank
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN role_type r ON c.role_id = r.id
    LEFT JOIN movie_info m ON c.movie_id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Role')
),
movies_with_cast AS (
    SELECT
        ft.title_id,
        ft.title,
        ft.production_year,
        ai.actor_name,
        ai.role_note,
        ft.year_rank,
        COUNT(ai.actor_name) OVER (PARTITION BY ft.production_year) AS actor_count
    FROM filtered_titles ft
    LEFT JOIN actor_info ai ON ft.title_id = ai.cast_id
),
final_selection AS (
    SELECT
        mwc.title,
        mwc.production_year,
        mwc.actor_name,
        mwc.role_note,
        mwc.year_rank,
        mwc.actor_count
    FROM movies_with_cast mwc
    WHERE mwc.year_rank <= 3 -- Top 3 titles per year
)

SELECT
    f.title,
    f.production_year,
    f.actor_name,
    f.role_note,
    f.actor_count,
    CASE
        WHEN f.actor_count > 5 THEN 'Ensemble Cast'
        WHEN f.actor_count IS NULL THEN 'No Cast Information'
        ELSE 'Standard Cast'
    END AS cast_type,
    CASE
        WHEN f.role_note LIKE '%lead%' THEN 'Lead Role'
        ELSE 'Support Role or Unknown'
    END AS role_classification
FROM final_selection f
ORDER BY f.production_year DESC, f.title;

-- Aggregating unconventional NULL logic and obscure semantics:
SELECT
    mi.movie_id,
    COUNT(DISTINCT coalesce(ai.actor_name, 'Unknown Actor')) AS unique_actors,
    COUNT(mi.info) AS total_movie_info,
    SUM(CASE WHEN mi.info IS NULL THEN 1 ELSE 0 END) AS null_info_count,
    MAX(COALESCE(title.title, 'Untitled')) AS effective_title
FROM movie_info mi
LEFT JOIN cast_info ci ON mi.movie_id = ci.movie_id
LEFT JOIN aka_name ai ON ci.person_id = ai.person_id
LEFT JOIN aka_title title ON mi.movie_id = title.movie_id
GROUP BY mi.movie_id
HAVING COUNT(DISTINCT ai.actor_name) > 0 AND COUNT(mi.info) < 10;
