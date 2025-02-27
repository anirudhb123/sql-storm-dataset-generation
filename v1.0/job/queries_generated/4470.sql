WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
actor_movie_count AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.person_id
),
top_actors AS (
    SELECT 
        a.id AS actor_id,
        a.name
    FROM aka_name a
    JOIN actor_movie_count amc ON a.person_id = amc.person_id
    WHERE amc.movie_count > 5
),
movies_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN title m ON mk.movie_id = m.id
    GROUP BY m.id
)
SELECT 
    rt.title,
    rt.production_year,
    ta.name AS top_actor,
    mwk.keywords,
    COALESCE(mci.note, 'No Company Details') AS company_note
FROM ranked_titles rt
LEFT JOIN top_actors ta ON rt.rank <= 3
LEFT JOIN complete_cast cc ON rt.title_id = cc.movie_id
LEFT JOIN movie_companies mci ON cc.movie_id = mci.movie_id 
LEFT JOIN movies_with_keywords mwk ON mwk.movie_id = rt.title_id
WHERE 
    mwk.keywords IS NOT NULL
    AND rt.production_year > 2000
ORDER BY rt.production_year DESC, rt.title;
