WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    WHERE a.production_year IS NOT NULL
    GROUP BY a.id, a.title, a.production_year
),
movie_details AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(inf.info, 'No info available') AS additional_info,
        k.keyword AS keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM ranked_movies m
    LEFT JOIN movie_info inf ON m.title = inf.info
    LEFT JOIN movie_keyword mk ON m.title = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE m.cast_count > 5
),
final_output AS (
    SELECT 
        md.title,
        md.production_year,
        md.additional_info,
        STRING_AGG(md.keyword, ', ') AS keywords,
        CASE 
            WHEN md.rank = 1 THEN 'Top Movie'
            WHEN md.rank < 5 THEN 'Featured Movie'
            ELSE 'Regular Movie'
        END AS categorization
    FROM movie_details md
    LEFT JOIN ranked_movies r ON md.title = r.title AND md.production_year = r.production_year
    WHERE md.keyword_rank IS NULL OR md.keyword_rank < 5
    GROUP BY md.title, md.production_year, md.additional_info, r.rank
)
SELECT 
    fo.*,
    (SELECT COUNT(*) FROM company_name cn WHERE fo.production_year - 5 <= 2023 AND cn.id IS NOT NULL) AS recent_companies,
    (SELECT MAX(r.rank) FROM ranked_movies r WHERE r.title = fo.title) AS max_rank
FROM final_output fo 
WHERE fo.keywords NOT LIKE '%action%'
ORDER BY fo.production_year DESC, fo.keywords;

This query is structured to achieve several performance benchmarks:

1. It uses a Common Table Expression (CTE) to first rank movies by the number of cast members, focusing on years with null productions as potential edge cases.
2. It aggregates keywords related to the movies, showing a complex use of COALESCE for handling missing data.
3. It dynamically categorizes movies based on their rank within the same year.
4. Subqueries are utilized to fetch the count of recent companies and the maximum rank of movies.
5. Finally, there is an exclusion of specific genres (`action`) to showcase a complicated filter based on keywords.
6. The final result is sorted to highlight the most recent pertinent movies first, setting up a multi-faceted benchmarking scenario focusing on performance across joins, CTEs, aggregations, and window functions.
