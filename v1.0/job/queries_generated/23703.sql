WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        title t
        LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.cast_count
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tt.title,
    tt.production_year,
    tt.cast_count,
    COALESCE(mk.keywords_list, 'No keywords') AS keywords,
    COALESCE(aka.name, 'Unknown') AS aka_name,
    COUNT(mc.company_id) AS company_count,
    ARRAY_AGG(DISTINCT ct.kind) AS company_types
FROM 
    TopTitles tt
    LEFT JOIN aka_title aka ON tt.title_id = aka.movie_id
    LEFT JOIN movie_companies mc ON tt.title_id = mc.movie_id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN MovieKeywords mk ON tt.title_id = mk.movie_id
GROUP BY 
    tt.title_id, tt.title, tt.production_year, tt.cast_count, mk.keywords_list, aka.name
HAVING 
    tt.production_year > 2000 
    AND COUNT(mc.company_id) > 0 
    AND tt.cast_count IS NOT NULL
ORDER BY 
    tt.production_year DESC, tt.cast_count DESC;

