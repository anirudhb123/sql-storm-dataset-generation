WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_agg AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS unique_actors,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
top_movies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        ca.unique_actors,
        ca.actor_names,
        RANK() OVER (ORDER BY ca.unique_actors DESC) AS actor_rank
    FROM 
        ranked_titles rt
    LEFT JOIN 
        cast_agg ca ON rt.title_id = ca.movie_id
    WHERE 
        rt.title IS NOT NULL
    ORDER BY 
        rt.production_year DESC
),
movies_with_keywords AS (
    SELECT 
        tm.title_id,
        tm.title,
        tm.production_year,
        kw.keyword
    FROM 
        top_movies tm
    LEFT JOIN 
        movie_keyword mk ON tm.title_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
)
SELECT 
    mwk.title,
    mwk.production_year,
    mwk.keyword,
    CASE 
        WHEN mwk.keyword IS NOT NULL THEN 'Has Keyword'
        ELSE 'No Keyword'
    END AS keyword_status,
    COALESCE(NULLIF(mwk.keyword, ''), 'Unknown') AS keyword_or_unknown
FROM 
    movies_with_keywords mwk
WHERE 
    mwk.production_year BETWEEN 2000 AND 2023
    AND (mwk.keyword IS NOT NULL OR mwk.keyword IS NULL)
UNION ALL
SELECT 
    'Total Titles' AS title,
    COUNT(*) AS production_year,
    NULL AS keyword,
    'Aggregation' AS keyword_status,
    NULL AS keyword_or_unknown
FROM 
    movies_with_keywords
HAVING 
    COUNT(*) > 5
ORDER BY 
    production_year DESC, title;
