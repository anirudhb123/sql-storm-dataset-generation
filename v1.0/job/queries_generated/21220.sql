WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    GROUP BY t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.keywords,
        md.cast_count,
        md.company_count,
        RANK() OVER (ORDER BY md.cast_count DESC, md.company_count DESC) AS rank_order
    FROM movie_details md
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(NULLIF(md.keywords, ''), 'No keywords') AS keywords,
    md.cast_count,
    md.company_count,
    CASE 
        WHEN md.rank_order <= 10 THEN 'Top Movie'
        ELSE 'Regular Movie'
    END AS category,
    EXISTS (
        SELECT 1
        FROM aka_title at
        WHERE at.title ILIKE '%' || md.title || '%'
    ) AS has_aka_title,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM person_info pi
            WHERE pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') 
            AND pi.person_id IN (SELECT DISTINCT person_id FROM cast_info ci WHERE ci.movie_id = md.title_id)
        ) THEN 'Rated'
        ELSE 'Not Rated'
    END AS rating_status
FROM top_movies md
WHERE md.rank_order <= 50
ORDER BY md.production_year DESC, md.cast_count DESC
OFFSET 5
LIMIT 15;

### Explanation of Constructs Used:
- **CTEs (Common Table Expressions)**: Two CTEs, `movie_details` for aggregating movie and cast information and `top_movies` for ranking the top films based on their cast and company involvement.
- **String Aggregation**: `STRING_AGG` to collect keywords related to each movie into a single string.
- **Window Functions**: `RANK()` to rank movies based on the number of casts and companies involved.
- **COALESCE and NULLIF**: Handle potentially NULL or empty keyword listings with custom output.
- **Correlated Subqueries**: To determine if there exists an alternate title containing the same text as the movie title.
- **CASE Statements**: Categorize movies into 'Top Movie' or 'Regular Movie' based on rank.
- **Predicate Logic**: Complex conditions using `EXISTS` to check for the presence of ratings based on associated person IDs from `cast_info`.
