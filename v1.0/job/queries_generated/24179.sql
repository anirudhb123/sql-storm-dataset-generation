WITH RankedTitles AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank,
        COUNT(ct.id) AS cast_count
    FROM aka_title at
    LEFT JOIN cast_info ci ON at.id = ci.movie_id
    LEFT JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY at.id, at.title, at.production_year
),
FilteredTitles AS (
    SELECT 
        rt.movie_title,
        rt.production_year,
        rt.cast_count,
        CASE 
            WHEN rt.cast_count IS NULL THEN 'No Cast' 
            WHEN rt.cast_count > 5 THEN 'Large Cast' 
            ELSE 'Small Cast' 
        END AS cast_size
    FROM RankedTitles rt
    WHERE rt.production_year IS NOT NULL
),
TitleKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN aka_title mt ON mk.movie_id = mt.id
    GROUP BY mt.movie_id
),
FinalResults AS (
    SELECT 
        ft.movie_title,
        ft.production_year,
        ft.cast_count,
        ft.cast_size,
        tk.keywords,
        CASE 
            WHEN ft.production_year < 2000 THEN 'Before Millennium'
            WHEN ft.production_year >= 2000 AND ft.production_year < 2010 THEN 'Noughties'
            ELSE '2010s and Beyond'
        END AS era
    FROM FilteredTitles ft
    LEFT JOIN TitleKeywords tk ON ft.movie_title = tk.movie_id
    WHERE ft.cast_size != 'No Cast'
)
SELECT 
    fr.production_year,
    COUNT(*) AS total_movies,
    SUM(CASE WHEN fr.cast_count IS NULL THEN 0 ELSE 1 END) AS movies_with_cast,
    STRING_AGG(DISTINCT fr.cast_size, ', ') AS cast_size_distribution,
    MAX(fr.cast_count) AS max_cast_count
FROM FinalResults fr
GROUP BY fr.production_year
ORDER BY fr.production_year DESC;
