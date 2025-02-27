
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(k.id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(k.id) DESC) AS rank_per_year
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year
),
TopRankedTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM RankedTitles rt
    WHERE rt.rank_per_year <= 5
),
MoviesWithTopTitles AS (
    SELECT 
        ct.id AS complete_cast_id,
        ct.movie_id,
        tt.title,
        tt.production_year,
        COUNT(ci.id) AS cast_count
    FROM complete_cast ct
    JOIN TopRankedTitles tt ON ct.movie_id = tt.title_id
    LEFT JOIN cast_info ci ON ct.movie_id = ci.movie_id
    GROUP BY ct.id, ct.movie_id, tt.title, tt.production_year
)
SELECT 
    mtt.title AS Movie_Title,
    mtt.production_year AS Production_Year,
    COUNT(DISTINCT ci.person_id) AS Total_Cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS Cast_Names
FROM MoviesWithTopTitles mtt
JOIN cast_info ci ON mtt.movie_id = ci.movie_id
JOIN aka_name ak ON ci.person_id = ak.person_id
GROUP BY mtt.title, mtt.production_year
ORDER BY mtt.production_year DESC, Total_Cast DESC;
