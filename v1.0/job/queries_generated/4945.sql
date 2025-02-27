WITH RecursiveTitleCTE AS (
    SELECT t.id, t.title, t.production_year, t.kind_id, 1 AS depth
    FROM title t
    WHERE t.production_year >= 2000
    UNION ALL
    SELECT t.id, t.title, t.production_year, t.kind_id, c.depth + 1
    FROM title t
    JOIN movie_link ml ON t.id = ml.linked_movie_id
    JOIN RecursiveTitleCTE c ON ml.movie_id = c.id
),
CastSummary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(CASE WHEN r.role = 'lead' THEN 1 ELSE 0 END) AS has_lead_role
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY ci.movie_id
),
TitleKeyword AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mt
    JOIN keyword k ON mt.keyword_id = k.id
    GROUP BY mt.movie_id
)
SELECT 
    t.id AS title_id,
    t.title AS movie_title,
    t.production_year,
    tt.total_cast,
    tt.has_lead_role,
    tk.keywords
FROM title t
LEFT JOIN CastSummary tt ON t.id = tt.movie_id
LEFT JOIN TitleKeyword tk ON t.id = tk.movie_id
WHERE 
    t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    AND (t.production_year IS NOT NULL OR t.production_year > 2000)
    AND (tt.total_cast IS NOT NULL OR tt.total_cast > 0)
ORDER BY 
    t.production_year DESC,
    t.title ASC
LIMIT 100;
