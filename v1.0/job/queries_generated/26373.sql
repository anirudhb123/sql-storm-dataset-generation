WITH RankedTitles AS (
    SELECT 
        a.id AS alias_id,
        a.name AS alias_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id

),
TitleKeywords AS (
    SELECT 
        rt.alias_id,
        rt.alias_name,
        rt.movie_title,
        rt.production_year,
        k.keyword AS movie_keyword
    FROM 
        RankedTitles rt
    JOIN 
        movie_keyword mk ON rt.alias_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    tk.alias_id,
    tk.alias_name,
    tk.movie_title,
    tk.production_year,
    STRING_AGG(tk.movie_keyword, ', ') AS keywords
FROM 
    TitleKeywords tk
WHERE 
    tk.title_rank = 1
GROUP BY 
    tk.alias_id, tk.alias_name, tk.movie_title, tk.production_year
ORDER BY 
    tk.production_year DESC;

This SQL query constructs a robust analysis of the top-ranked movie titles associated with each person (from the `aka_name` table) based on their most recent releases and aggregates their corresponding keywords. It employs Common Table Expressions (CTEs) to first rank the titles and then retrieve keywords, showcasing advanced string processing functionalities alongside SQL aggregations and joins.
