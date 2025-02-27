
WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.id) AS title_rank
    FROM aka_title at
),
TitleKeyword AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
PersonRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS role_count,
        STRING_AGG(DISTINCT ct.kind, ', ') AS role_types
    FROM cast_info ci
    JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY ci.movie_id
),
FilteredMovies AS (
    SELECT
        at.id AS movie_id,
        at.title,
        at.production_year,
        COALESCE(tk.keywords, 'No keywords') AS keywords,
        COALESCE(pr.role_count, 0) AS role_count,
        COALESCE(pr.role_types, 'No roles') AS role_types
    FROM aka_title at
    LEFT JOIN TitleKeyword tk ON at.id = tk.movie_id
    LEFT JOIN PersonRoles pr ON at.id = pr.movie_id
    WHERE at.production_year >= 2000
      AND (at.kind_id IS NOT NULL OR at.kind_id IS NOT NULL)
)
SELECT
    fm.title,
    fm.production_year,
    fm.keywords,
    fm.role_count,
    fm.role_types,
    CASE 
        WHEN fm.role_count > 5 THEN 'Ensemble Cast'
        WHEN fm.role_count = 0 THEN 'No Cast'
        ELSE 'Standard Cast'
    END AS cast_category,
    ARRAY_AGG(DISTINCT a.name) AS actors
FROM FilteredMovies fm
JOIN cast_info ci ON fm.movie_id = ci.movie_id
JOIN aka_name a ON ci.person_id = a.person_id
GROUP BY fm.title, fm.production_year, fm.keywords, fm.role_count, fm.role_types
ORDER BY fm.production_year DESC, fm.role_count DESC
LIMIT 50;
