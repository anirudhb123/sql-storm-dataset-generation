WITH recursive actor_movies AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT ct.movie_id) AS movie_count,
        STRING_AGG(DISTINCT ct.title, ', ') AS titles,
        MAX(t.production_year) AS latest_year
    FROM cast_info ca
    JOIN aka_name an ON ca.person_id = an.person_id
    JOIN aka_title at ON ca.movie_id = at.movie_id
    JOIN title t ON ca.movie_id = t.id
    LEFT JOIN movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = 1
    WHERE an.name IS NOT NULL
    GROUP BY ca.person_id
),
movies_with_keyword_count AS (
    SELECT 
        t.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    GROUP BY t.id
),
top_movies AS (
    SELECT 
        m.movie_id,
        m.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY m.keyword_count ORDER BY t.production_year DESC) AS rank
    FROM movies_with_keyword_count m
    JOIN title t ON m.movie_id = t.id
    WHERE t.production_year IS NOT NULL
),
actor_top_movies AS (
    SELECT 
        am.person_id,
        am.titles,
        am.latest_year,
        tm.keyword_count
    FROM actor_movies am
    JOIN top_movies tm ON am.movie_count > 1 AND tm.rank <= 10
    WHERE am.latest_year IS NOT NULL
)
SELECT 
    an.name,
    at.movie_id,
    at.titles,
    at.latest_year,
    at.keyword_count,
    COALESCE(at.keyword_count, 0) AS non_zero_keyword_count,
    CASE 
        WHEN at.keyword_count IS NULL THEN 'No Keywords'
        WHEN at.keyword_count = 0 THEN 'Zero Keywords'
        ELSE 'Has Keywords'
    END AS keyword_status,
    ARRAY_AGG(DISTINCT COALESCE(ct.kind, 'Unknown')) AS company_kinds
FROM actor_top_movies at
LEFT JOIN aka_name an ON at.person_id = an.person_id
LEFT JOIN movie_companies mc ON at.movie_id = mc.movie_id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
GROUP BY an.name, at.movie_id, at.latest_year, at.keyword_count
ORDER BY at.latest_year DESC, an.name;
