WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
FilteredTitles AS (
    SELECT 
        title_id,
        title,
        production_year,
        STRING_AGG(keyword, ', ') AS keywords
    FROM 
        RankedTitles
    WHERE 
        keyword_rank <= 3  
    GROUP BY 
        title_id, title, production_year
)
SELECT 
    a.name AS actor_name,
    ft.title,
    ft.production_year,
    ft.keywords,
    c.kind AS cast_type,
    COUNT(DISTINCT ft.title_id) AS total_titles
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    FilteredTitles ft ON cc.movie_id = ft.title_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name, ft.title, ft.production_year, ft.keywords, c.kind
ORDER BY 
    total_titles DESC, actor_name;