WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM title t
    WHERE t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        p.name AS person_name,
        t.title AS movie_title, 
        m.company_id,
        m.note AS company_note,
        ci.note AS cast_note,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ci.nr_order) AS role_rank
    FROM movie_companies m
    JOIN aka_title t ON m.movie_id = t.id
    JOIN cast_info ci ON m.movie_id = ci.movie_id
    JOIN aka_name p ON ci.person_id = p.person_id
    WHERE m.company_type_id IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        mt.movie_title,
        mt.person_name,
        mt.company_note,
        mt.cast_note,
        COALESCE(NULLIF(mt.company_note, ''), 'N/A') AS effective_company_note,
        mt.role_rank
    FROM MovieDetails mt
    WHERE mt.role_rank <= 3
)
SELECT 
    DISTINCT fm.movie_title,
    fm.person_name,
    fm.effective_company_note
FROM FilteredMovies fm
LEFT JOIN keyword k ON EXISTS (
    SELECT 1 
    FROM movie_keyword mk 
    WHERE mk.movie_id = (SELECT id FROM aka_title WHERE title = fm.movie_title LIMIT 1)
      AND mk.keyword_id = k.id
)
ORDER BY fm.movie_title, fm.person_name
LIMIT 100;
