WITH RecursiveMovie AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT c.name) AS cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank,
        COUNT(DISTINCT cm.company_id) AS company_count
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        aka_name c ON c.person_id = ci.person_id 
    LEFT JOIN 
        movie_companies cm ON cm.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopTitles AS (
    SELECT 
        title_id, title, production_year, cast, company_count,
        CASE 
            WHEN company_count > 5 THEN 'Blockbuster'
            WHEN company_count BETWEEN 3 AND 5 THEN 'Moderate'
            ELSE 'Indie'
        END AS label
    FROM 
        RecursiveMovie
    WHERE 
        year_rank <= 5
),
FilteredTitles AS (
    SELECT 
        tt.title_id, tt.title, tt.production_year, tt.cast, tt.label,
        COALESCE(mk.keywords, '{}') AS keywords
    FROM 
        TopTitles tt
    LEFT JOIN (
        SELECT 
            mt.movie_id,
            ARRAY_AGG(DISTINCT k.keyword) AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON k.id = mk.keyword_id
        GROUP BY 
            mt.movie_id
    ) mk ON mk.movie_id = tt.title_id
)
SELECT 
    ft.title_id,
    ft.title,
    ft.production_year,
    ft.cast,
    ft.label,
    ft.keywords,
    NULLIF(ft.production_year, '') AS year_placeholder,
    CASE 
        WHEN ft.label = 'Blockbuster' THEN COUNT(ft.title_id) OVER (PARTITION BY ft.label)
        ELSE NULL
    END AS blockbuster_count,
    LEAD(ft.title) OVER (ORDER BY ft.production_year) AS next_title
FROM 
    FilteredTitles ft
WHERE 
    ft.production_year > 2000
ORDER BY 
    ft.production_year DESC, ft.label DESC;
