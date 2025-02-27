
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        RANK() OVER (PARTITION BY t.id ORDER BY k.keyword) AS rank_keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
FilteredTitles AS (
    SELECT DISTINCT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank_keyword <= 5
),
CollatedInfo AS (
    SELECT 
        f.title_id, 
        f.title,
        f.production_year,
        STRING_AGG(DISTINCT p.info, ', ') AS person_info,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        FilteredTitles f
    LEFT JOIN 
        complete_cast cc ON f.title_id = cc.movie_id
    LEFT JOIN 
        person_info p ON cc.subject_id = p.person_id
    LEFT JOIN 
        cast_info c ON cc.movie_id = c.movie_id
    GROUP BY 
        f.title_id, f.title, f.production_year
)
SELECT 
    ci.title,
    ci.production_year,
    ci.person_info,
    ci.cast_count
FROM 
    CollatedInfo ci
WHERE 
    ci.cast_count > 10
ORDER BY 
    ci.production_year DESC, 
    ci.cast_count DESC;
