WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(mk.movie_id) AS keyword_count
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
FilteredTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.keyword,
        rt.keyword_count,
        RANK() OVER (PARTITION BY rt.production_year ORDER BY rt.keyword_count DESC) AS rank
    FROM 
        RankedTitles rt
    WHERE 
        rt.production_year IS NOT NULL
),
MostPopularTitles AS (
    SELECT 
        ft.title_id,
        ft.title,
        ft.production_year,
        ft.keyword,
        ft.keyword_count
    FROM 
        FilteredTitles ft
    WHERE 
        ft.rank = 1
)
SELECT 
    ft.title,
    ft.production_year,
    ak.name AS actor_name,
    ARRAY_AGG(DISTINCT c.role_id) AS roles,
    ARRAY_AGG(DISTINCT c.note) AS notes
FROM 
    MostPopularTitles ft
LEFT JOIN 
    movie_info mi ON ft.title_id = mi.movie_id
LEFT JOIN 
    cast_info c ON ft.title_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
GROUP BY 
    ft.title_id, ft.title, ft.production_year, ak.name
ORDER BY 
    ft.production_year DESC;
