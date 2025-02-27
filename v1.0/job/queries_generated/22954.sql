WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),

AggregatedNames AS (
    SELECT 
        a.person_id,
        STRING_AGG(DISTINCT a.name, ', ') AS all_names,
        COUNT(DISTINCT a.id) AS name_count
    FROM 
        aka_name a
    GROUP BY 
        a.person_id
),

TitleKeywordCount AS (
    SELECT 
        t.id AS title_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    GROUP BY 
        t.id
)

SELECT 
    rt.aka_name,
    rt.title,
    rt.production_year,
    an.all_names,
    COALESCE(tkc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN t.production_year > 2000 THEN 'Modern'
        WHEN t.production_year BETWEEN 1980 AND 2000 THEN 'Classic'
        ELSE 'Old'
    END AS era_label
FROM 
    RankedTitles rt
JOIN 
    AggregatedNames an ON rt.aka_id = an.person_id
LEFT JOIN 
    TitleKeywordCount tkc ON rt.id = tkc.title_id
WHERE 
    rt.rn = 1
    AND EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = rt.id 
          AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
          AND mi.info IS NOT NULL
    )
ORDER BY 
    rt.production_year DESC, 
    keyword_count DESC;
