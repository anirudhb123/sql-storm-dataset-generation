WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY t.production_year ORDER BY a.name) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
TitleKeywords AS (
    SELECT 
        t.id AS title_id,
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    rt.actor_name,
    rt.actor_rank,
    tk.keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    TitleKeywords tk ON rt.title_id = tk.title_id
WHERE 
    rt.production_year >= 2000 AND 
    rt.actor_rank <= 3
ORDER BY 
    rt.production_year DESC, 
    rt.actor_rank ASC;

This elaborate SQL query performs the following operations to benchmark string processing:

1. **Common Table Expressions (CTEs)**:
   - `RankedTitles`: Ranks actors for each movie by name within the same production year.
   - `TitleKeywords`: Aggregates keywords associated with each movie into a comma-separated string.

2. **Main Query**: Selects the title ID, title, production year, actor name, actor rank, and keywords for movies produced in or after 2000, restricting the results to the top 3 actors per movie.

3. **Ordering**: The results are ordered by production year in descending order and then by actor rank in ascending order. 

This complex query showcases multiple joins, string aggregation, and window functions — ideal for benchmarking string processing performance in SQL.
