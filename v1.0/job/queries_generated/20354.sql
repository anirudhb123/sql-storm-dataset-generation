WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS title_rank,
        COUNT(t.id) OVER (PARTITION BY t.production_year) AS title_count
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
),
TitleInfo AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        CASE 
            WHEN rt.title_count > 5 THEN 'Popular' 
            WHEN rt.title_count BETWEEN 3 AND 5 THEN 'Moderate' 
            ELSE 'Niche' 
        END AS popularity
    FROM 
        RankedTitles AS rt
),
FilteredTitles AS (
    SELECT 
        ti.title,
        ti.production_year,
        ti.popularity
    FROM 
        TitleInfo AS ti
    WHERE 
        ti.popularity <> 'Niche'
)
SELECT 
    ak.name AS actor_name,
    ft.title,
    ft.production_year,
    COALESCE(c.name, 'Unknown Company') AS production_company,
    CASE 
        WHEN ft.production_year < 2000 THEN 'Classic'
        WHEN ft.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    COUNT(ci.person_id) AS actor_count
FROM 
    cast_info AS ci
JOIN 
    aka_name AS ak ON ci.person_id = ak.person_id
JOIN 
    aka_title AS at ON ci.movie_id = at.movie_id
JOIN 
    FilteredTitles AS ft ON at.id = ft.title_id
LEFT JOIN 
    movie_companies AS mc ON mc.movie_id = ci.movie_id
LEFT JOIN 
    company_name AS c ON mc.company_id = c.id
WHERE 
    ak.name IS NOT NULL
    AND ft.production_year > 1990
GROUP BY 
    ak.name, ft.title, ft.production_year, c.name
HAVING 
    COUNT(ci.person_id) > 1
ORDER BY 
    ft.production_year DESC, ak.name ASC;
