WITH movie_summary AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        SUM(CASE WHEN mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'budget') THEN CAST(mi.info AS numeric) ELSE 0 END) AS total_budget,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM aka_title a
    LEFT JOIN cast_info ci ON a.id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN movie_info mi ON a.id = mi.movie_id
    GROUP BY a.id
),
top_movies AS (
    SELECT 
        title, 
        production_year, 
        cast_count, 
        actors,
        total_budget,
        rank
    FROM movie_summary
    WHERE rank <= 5
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(t.cast_count, 0) AS total_cast,
    COALESCE(t.actors, 'No actors available') AS actor_list,
    CASE 
        WHEN t.total_budget IS NULL THEN 'Budget information not available'
        ELSE '$' || TO_CHAR(t.total_budget, 'FM999,999,999')
    END AS formatted_budget
FROM top_movies t
FULL OUTER JOIN info_type it ON it.id IN (SELECT DISTINCT info_type_id FROM movie_info WHERE movie_id IN (SELECT id FROM aka_title WHERE production_year = 2023))
WHERE it.info IS NOT NULL
ORDER BY t.production_year DESC, t.cast_count DESC;
