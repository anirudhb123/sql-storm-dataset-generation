WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT kc.id) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
TopTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.kind_id,
        rt.keyword_count,
        rt.keywords_list,
        RANK() OVER (ORDER BY rt.keyword_count DESC) AS rank_keyword
    FROM 
        RankedTitles rt
)
SELECT 
    tt.title_id,
    tt.title,
    tt.production_year,
    kt.kind,
    tt.keyword_count,
    tt.keywords_list
FROM 
    TopTitles tt
JOIN 
    kind_type kt ON tt.kind_id = kt.id
WHERE 
    tt.rank_keyword <= 10  -- Get top 10 titles by keyword count
ORDER BY 
    tt.keyword_count DESC;
