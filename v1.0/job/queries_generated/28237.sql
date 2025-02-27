WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title AS title_name,
        t.production_year,
        k.keyword AS keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY p.info) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        info_type it ON mi.info_type_id = it.id
    JOIN 
        person_info pi ON t.id = pi.person_id
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN 
        aka_name an ON at.id = an.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year > 2000 
        AND k.keyword IS NOT NULL
),
FilteredTitles AS (
    SELECT 
        title_id,
        title_name,
        production_year,
        keyword
    FROM 
        RankedTitles
    WHERE 
        rank = 1
)
SELECT 
    f.title_name,
    f.production_year,
    COUNT(f.keyword) AS keyword_count,
    STRING_AGG(DISTINCT f.keyword, ', ') AS keywords
FROM 
    FilteredTitles f
GROUP BY 
    f.title_id, f.title_name, f.production_year
ORDER BY 
    f.production_year DESC, keyword_count DESC
LIMIT 100;
