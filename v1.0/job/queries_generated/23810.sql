WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank,
        COUNT(mk.movie_id) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
CompleteCastInfo AS (
    SELECT 
        cc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS complete_cast_names,
        COUNT(DISTINCT ci.person_role_id) AS role_count,
        MAX(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name cn ON cn.person_id = ci.person_id
    GROUP BY 
        cc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    rti.complete_cast_names,
    rti.role_count,
    rti.has_note,
    rt.keyword_count,
    CASE 
        WHEN rt.keyword_count = 0 THEN 'No Keywords'
        WHEN rt.keyword_count >= 5 THEN 'High Keywords'
        ELSE 'Medium Keywords' 
    END AS keyword_classification,
    -- Demonstrating NULL logic
    COALESCE(rti.has_note, 0) AS has_notes_or_zero,
    NULLIF(rti.role_count, 0) AS non_zero_role_count
FROM 
    RankedTitles rt
LEFT JOIN 
    CompleteCastInfo rti ON rt.title_id = rti.movie_id
WHERE 
    rt.rank <= 5
ORDER BY 
    rt.production_year DESC, 
    rt.title;
