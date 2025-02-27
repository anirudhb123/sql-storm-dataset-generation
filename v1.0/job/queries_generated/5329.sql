WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.id) DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    GROUP BY 
        t.id, t.title, t.production_year
),
DetailedInfo AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.company_count,
        COUNT(DISTINCT ki.id) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        RankedTitles rt
    LEFT JOIN 
        movie_keyword mk ON rt.title = (SELECT title FROM title WHERE id = mk.movie_id)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        rt.rank = 1
    GROUP BY 
        rt.title, rt.production_year, rt.company_count
)
SELECT 
    di.title,
    di.production_year,
    di.company_count,
    di.keyword_count,
    di.keywords
FROM 
    DetailedInfo di
WHERE 
    di.company_count > 0
ORDER BY 
    di.production_year DESC, 
    di.keyword_count DESC;
