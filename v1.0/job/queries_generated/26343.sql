WITH TitleStats AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(DISTINCT m.id) AS company_count,
        COUNT(DISTINCT c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY t.id, t.title, t.production_year, k.keyword
),
Keywords AS (
    SELECT 
        title_id,
        STRING_AGG(DISTINCT keyword, ', ') AS all_keywords
    FROM TitleStats
    GROUP BY title_id
),
FinalStats AS (
    SELECT 
        ts.title_id,
        ts.title,
        ts.production_year,
        ts.company_count,
        ts.cast_count,
        k.all_keywords,
        ts.actor_names
    FROM TitleStats ts
    JOIN Keywords k ON ts.title_id = k.title_id
)
SELECT 
    title_id,
    title,
    production_year,
    company_count,
    cast_count,
    all_keywords,
    actor_names
FROM FinalStats
ORDER BY production_year DESC, title;
