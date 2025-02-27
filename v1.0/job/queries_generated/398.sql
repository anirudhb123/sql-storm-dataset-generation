WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
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
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    COALESCE(tk.keywords, 'No Keywords') AS movie_keywords,
    cd.total_cast,
    COALESCE(cd.cast_names, 'No Cast Info') AS cast_info,
    CASE 
        WHEN rt.title_rank = 1 THEN 'Top Title of the Year'
        ELSE NULL
    END AS title_ranking,
    x.* 
FROM RankedTitles rt
LEFT JOIN TitleKeywords tk ON rt.title_id = tk.movie_id
LEFT JOIN CastDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN (
    SELECT DISTINCT
        t.kind_id,
        k.kind,
        COUNT(*) AS title_count
    FROM title t
    JOIN kind_type k ON t.kind_id = k.id
    GROUP BY t.kind_id, k.kind
) x ON x.kind_id = rt.title_id
ORDER BY rt.production_year DESC, rt.title;
