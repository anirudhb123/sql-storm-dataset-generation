WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cm.id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
SelectedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        cm.total_companies,
        cm.company_names
    FROM 
        RankedMovies rm
    JOIN 
        CompanyStats cm ON rm.movie_id = cm.movie_id
    WHERE 
        rm.rank <= 5  -- Get top 5 movies per production year
)
SELECT 
    sm.title,
    sm.production_year,
    sm.total_companies,
    sm.company_names,
    COALESCE(SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS note_presence,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = sm.movie_id AND mi.info LIKE '%Oscar%') AS oscar_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    SelectedMovies sm
LEFT JOIN 
    movie_keyword mk ON sm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON sm.movie_id = mi.movie_id AND mi.note IS NOT NULL
LEFT JOIN 
    cast_info c ON sm.movie_id = c.movie_id 
GROUP BY 
    sm.title, sm.production_year, sm.total_companies, sm.company_names
ORDER BY 
    sm.production_year DESC, sm.total_companies DESC
LIMIT 10;


### Explanation of the Query:
1. **CTEs**:
   - **RankedMovies**: Identifies movies ranked by the count of distinct cast members for each production year.
   - **CompanyStats**: Aggregates company data related to each movie.
   - **SelectedMovies**: Filters for the top five movies per production year based on cast count.

2. **Main SELECT Statement**:
   - Pulls together movie details along with aggregated company information and additional metrics such as notes presence and Oscar count.
   - Uses `COALESCE` to handle potential NULL values in note presence tracking.
   - Aggregates keywords related to movies.

3. **Joins**: 
   - Looks up company names, keywords, and relevant movie information with outer joins to ensure movies without companies or keywords are still accessible.

4. **Ordering and Limiting**: 
   - Orders results by production year and number of companies, and limits the results to the top 10, showcasing the most recent, most collaborative movies in the dataset.
