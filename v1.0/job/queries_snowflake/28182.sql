
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TitleKeywords AS (
    SELECT 
        t.id AS title_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),
TopRankedTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.cast_count,
        tk.keywords
    FROM 
        RankedTitles rt
    JOIN 
        TitleKeywords tk ON rt.title_id = tk.title_id
    WHERE 
        rt.rank_per_year <= 5
)
SELECT 
    t.title,
    t.production_year,
    t.cast_count,
    t.keywords
FROM 
    TopRankedTitles t
ORDER BY 
    t.production_year, t.cast_count DESC;
