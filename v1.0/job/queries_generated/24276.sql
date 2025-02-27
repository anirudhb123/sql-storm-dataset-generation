WITH RecursiveCTE AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT t.id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS titles
    FROM 
        cast_info ca
    JOIN 
        aka_name an ON ca.person_id = an.person_id
    JOIN 
        aka_title t ON ca.movie_id = t.movie_id
    WHERE 
        an.name IS NOT NULL 
        AND ca.nr_order IS NOT NULL
    GROUP BY 
        ca.person_id
    HAVING 
        COUNT(DISTINCT t.id) > 2
),
FilteredTitles AS (
    SELECT 
        r.person_id,
        r.titles,
        r.movie_count,
        ROW_NUMBER() OVER (PARTITION BY r.person_id ORDER BY r.movie_count DESC) AS rn
    FROM 
        RecursiveCTE r
    WHERE 
        r.titles NOT LIKE '%Unknown%' AND r.titles NOT LIKE '%TBA%'
),
TopTitles AS (
    SELECT 
        ft.person_id,
        ft.titles
    FROM 
        FilteredTitles ft
    WHERE 
        ft.rn = 1
)
SELECT 
    an.name AS actor_name,
    tt.titles,
    COALESCE(CAST(COUNT(DISTINCT mc.company_id) AS INT), 0) AS company_count,
    SUM(CASE 
            WHEN mt.info IS NOT NULL THEN 1
            ELSE 0 
        END) AS movie_info_available
FROM 
    TopTitles tt
JOIN 
    aka_name an ON tt.person_id = an.person_id
LEFT JOIN 
    movie_companies mc ON tt.person_id = mc.movie_id
LEFT JOIN 
    movie_info mt ON mc.movie_id = mt.movie_id
GROUP BY 
    an.name, tt.titles
HAVING 
    COUNT(DISTINCT mc.company_id) > 0 
    OR SUM(CASE 
            WHEN mt.info IS NULL THEN 1 
            ELSE 0 
        END) < 5
ORDER BY 
    company_count DESC, actor_name ASC
LIMIT 50;

-- Edge case: handling situations where titles contain NULL or empty strings
-- and ensuring division by zero does not occur when calculating averages.
SELECT 
    an.name,
    COALESCE(AVG(CASE WHEN mt.info IS NOT NULL THEN 1 ELSE 0 END), 0) AS avg_info_per_movie
FROM 
    aka_name an
LEFT JOIN 
    movie_companies mc ON an.person_id = mc.movie_id
LEFT JOIN 
    movie_info mt ON mc.movie_id = mt.movie_id
WHERE 
    an.name IS NOT NULL
GROUP BY 
    an.name
HAVING 
    COUNT(DISTINCT mt.movie_id) > 0 
    AND COUNT(DISTINCT mt.info_type_id) > 3
ORDER BY 
    avg_info_per_movie DESC
LIMIT 10;
