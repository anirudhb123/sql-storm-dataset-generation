WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT tk.keyword) AS keyword_count
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        cast_info c ON at.movie_id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword tk ON mk.keyword_id = tk.id
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedTitlesWithRank AS (
    SELECT 
        title_id,
        title,
        production_year,
        cast_count,
        keyword_count,
        RANK() OVER (ORDER BY cast_count DESC, keyword_count DESC) AS rank
    FROM 
        RankedTitles
),
FilteredTitles AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.cast_count,
        rt.keyword_count
    FROM 
        RankedTitlesWithRank rt
    WHERE 
        rt.rank <= 10
)
SELECT 
    ft.title,
    ft.production_year,
    ft.cast_count,
    ft.keyword_count,
    ARRAY_AGG(DISTINCT ak.name) AS aka_names
FROM 
    FilteredTitles ft
LEFT JOIN 
    aka_name ak ON ak.person_id IN (SELECT c.person_id FROM cast_info c WHERE c.movie_id IN (SELECT title_id FROM RankedTitles))
GROUP BY 
    ft.title, ft.production_year, ft.cast_count, ft.keyword_count
ORDER BY 
    ft.cast_count DESC
LIMIT 10;
