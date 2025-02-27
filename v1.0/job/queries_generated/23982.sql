WITH RecursiveCTE AS (
    SELECT 
        a.id AS aka_id, 
        a.person_id, 
        a.name AS aka_name, 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
),
FilteredCTE AS (
    SELECT 
        *,
        CASE 
            WHEN rn = 1 THEN 'Latest'
            ELSE 'Earlier'
        END AS name_rank
    FROM 
        RecursiveCTE
)
SELECT 
    f.aka_id, 
    f.aka_name, 
    f.movie_title,
    f.production_year,
    COALESCE(c.name, 'Unknown Company') AS company_name,
    COALESCE(STRING_AGG(DISTINCT k.keyword, ', '), 'No Keywords') AS keywords,
    COUNT(DISTINCT cm.company_id) AS num_companies
FROM 
    FilteredCTE f
LEFT JOIN 
    complete_cast cc ON f.title_id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = cc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON f.title_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON f.title_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget' LIMIT 1)
WHERE 
    f.name_rank = 'Latest'
    AND (f.production_year IS NOT NULL AND f.production_year > 2000)
    AND (c.country_code IS NULL OR c.country_code NOT IN ('USA', 'CAN'))
GROUP BY 
    f.aka_id, f.aka_name, f.movie_title, f.production_year, c.name
HAVING 
    COUNT(DISTINCT mc.company_id) >= 2
ORDER BY 
    f.production_year DESC, f.aka_name;
