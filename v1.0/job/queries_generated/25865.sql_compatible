
WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ct.kind AS company_type,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        a.movie_id
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.movie_id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        complete_cast cc ON a.movie_id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.title, a.production_year, ct.kind, a.movie_id
),
KeywordCounts AS (
    SELECT 
        a.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    GROUP BY 
        a.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    rt.company_type,
    rt.cast_count,
    rt.aka_names,
    kc.keyword_count
FROM 
    RankedTitles rt
JOIN 
    KeywordCounts kc ON rt.movie_id = kc.movie_id
ORDER BY 
    rt.production_year DESC, 
    rt.cast_count DESC;
