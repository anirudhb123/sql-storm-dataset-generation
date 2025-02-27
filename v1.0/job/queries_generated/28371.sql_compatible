
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(k.id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), 
TitleDetails AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.keyword_count,
        ak.name AS actor_name,
        COUNT(c.id) AS cast_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        complete_cast cc ON rt.title_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        rt.title_id, rt.title, rt.production_year, rt.keyword_count, ak.name
    ORDER BY 
        rt.keyword_count DESC
),
FinalResults AS (
    SELECT 
        td.title,
        td.production_year,
        td.keyword_count,
        STRING_AGG(DISTINCT td.actor_name, ', ') AS actors,
        td.cast_count
    FROM 
        TitleDetails td
    GROUP BY 
        td.title, td.production_year, td.keyword_count, td.cast_count
)
SELECT 
    title,
    production_year,
    keyword_count,
    actors,
    cast_count
FROM 
    FinalResults
WHERE 
    keyword_count > 0
ORDER BY 
    production_year DESC, 
    keyword_count DESC;
