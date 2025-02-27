WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS title_rank
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title t ON ci.movie_id = t.movie_id
    WHERE t.production_year IS NOT NULL
),
TitleKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mt
    JOIN keyword k ON mt.keyword_id = k.id
    GROUP BY mt.movie_id
),
ActorMovieInfo AS (
    SELECT 
        ni.name AS actor_name,
        ti.title AS movie_title,
        ti.production_year,
        COALESCE(tk.keywords, 'No Keywords') AS keywords,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
    FROM ranked_titles rt
    JOIN title ti ON rt.movie_title = ti.title AND rt.production_year = ti.production_year
    LEFT JOIN TitleKeywords tk ON ti.id = tk.movie_id
    LEFT JOIN cast_info ci ON ci.movie_id = ti.id
    WHERE rt.title_rank = 1
    GROUP BY ni.name, ti.title, ti.production_year, tk.keywords
),
ConditionFilteredActors AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        keywords,
        null_notes_count,
        ROW_NUMBER() OVER (PARTITION BY keywords ORDER BY production_year DESC) AS keyword_group_rank
    FROM ActorMovieInfo
    WHERE null_notes_count > 0 OR keywords LIKE '%action%'
),
FinalOutput AS (
    SELECT 
        actor_name,
        movie_title,
        production_year, 
        keywords,
        NULLIF(keyword_group_rank, 1) AS rank_adjustment
    FROM ConditionFilteredActors
    WHERE production_year >= 2000
    ORDER BY production_year DESC, actor_name ASC
)
SELECT 
    f.actor_name,
    f.movie_title,
    f.production_year,
    COALESCE(f.keywords, 'No keywords available') AS keywords,
    f.rank_adjustment
FROM FinalOutput f
WHERE f.rank_adjustment IS NOT NULL
UNION ALL
SELECT 
    DISTINCT ni.name,
    ti.title,
    ti.production_year,
    'Aggregated from other movies' AS keywords,
    NULL
FROM name ni 
JOIN title ti ON ni.imdb_id = ti.imdb_id
WHERE ni.gender = 'F'
AND ti.production_year < 2000
ORDER BY actor_name, movie_title;
