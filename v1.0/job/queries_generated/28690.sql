WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        movie_info m ON t.id = m.movie_id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
        AND LENGTH(t.title) > 5
),

keyword_summary AS (
    SELECT 
        t.id AS title_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        ranked_titles t
    LEFT JOIN 
        movie_keyword mk ON t.title_id = mk.movie_id
    GROUP BY 
        t.id
),

final_output AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.actor_name,
        rt.actor_rank,
        ks.keyword_count
    FROM 
        ranked_titles rt
    JOIN 
        keyword_summary ks ON rt.title_id = ks.title_id
    ORDER BY 
        rt.production_year DESC, 
        ks.keyword_count DESC, 
        rt.actor_rank
)

SELECT 
    title_id, 
    title, 
    production_year, 
    actor_name, 
    actor_rank, 
    keyword_count
FROM 
    final_output
WHERE 
    actor_rank <= 3
LIMIT 100;

This query performs the following operations:

1. **ranked_titles CTE**: It fetches titles from `aka_title`, along with actors' names associated with each title, and ranks them by their order in the cast.
2. **keyword_summary CTE**: It summarizes keyword counts for each title from the `movie_keyword` table.
3. **final_output CTE**: It consolidates data from `ranked_titles` and `keyword_summary` for the final result.
4. **Final SELECT**: It retrieves the top three actors for each title along with its keyword count, filtered by the actor rank, and limits the results to 100 titles. 

This SQL query can act as a benchmark for string processing, particularly around joining multiple tables and handling string data efficiently.
