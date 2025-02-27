WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank_per_year <= 5
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_casts,
        MAX(c.ct.kind) AS company_type
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
)
SELECT 
    tt.title,
    md.movie_id,
    md.total_casts,
    md.production_year,
    CASE 
        WHEN md.company_type IS NULL THEN 'No Companies'
        ELSE md.company_type
    END AS company_type_description,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = md.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Running Time')) AS runtime_info,
    (SELECT STRING_AGG(kw.keyword, ', ') 
     FROM movie_keyword mk
     JOIN keyword kw ON mk.keyword_id = kw.id 
     WHERE mk.movie_id = md.movie_id) AS keywords
FROM 
    TopTitles tt
JOIN 
    MovieDetails md ON tt.title_id = md.movie_id
ORDER BY 
    md.production_year DESC, 
    md.total_casts DESC;

This SQL query performs several sophisticated operations within the provided schema, including:

1. **Common Table Expressions (CTEs)**: `RankedTitles`, `TopTitles`, and `MovieDetails` are used to break down the problem into manageable parts.
2. **Window Functions**: A ranking of titles by production year is performed to extract the top 5 titles per year.
3. **Outer Joins**: A left join on `cast_info` allows for movies without cast information to still be included in the results.
4. **Subqueries** within the main select statement provide additional aggregated data like running time and keywords associated with each movie.
5. **Complicated Case Logic**: Displays a custom message for movies without associated companies.
6. **Aggregate Function**: `COUNT(DISTINCT ci.person_id)` counts unique casts, and `STRING_AGG` combines keywords into a single string.
7. **NULL Logic**: Specifically handles NULL values for company descriptions.

The final result offers a comprehensive view of the top titles along with their metadata in a well-structured format.
