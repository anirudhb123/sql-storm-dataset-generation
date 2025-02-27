WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastInfoWithRoles AS (
    SELECT 
        ci.id AS cast_id,
        ci.movie_id,
        ci.person_id,
        rk.role AS role,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        role_type rk ON ci.role_id = rk.id
),
MovieDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT CONCAT(an.name, ' as ', ci.role), ', ') FILTER (WHERE ci.role IS NOT NULL) AS cast_list
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastInfoWithRoles ci ON rm.title_id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        rm.title_id, rm.title, rm.production_year
),
MostPopularTitles AS (
    SELECT 
        md.*,
        RANK() OVER (ORDER BY md.cast_count DESC) AS popularity_rank
    FROM 
        MovieDetails md
    WHERE 
        md.cast_count > 0 
)
SELECT 
    m.title,
    m.production_year,
    m.cast_count,
    m.cast_list,
    COALESCE(k.keyword, 'No Keywords') AS movie_keyword,
    CASE 
        WHEN m.popularity_rank <= 10 THEN 'Top 10'
        ELSE 'Below Top 10'
    END AS ranking_category
FROM 
    MostPopularTitles m
LEFT JOIN 
    movie_keyword mk ON m.title_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.cast_count >= (SELECT AVG(cast_count) FROM MovieDetails) 
    AND COALESCE(m.cast_list, '') <> ''
ORDER BY 
    m.cast_count DESC, m.title
LIMIT 50;

### Query Explanation:
1. **Common Table Expressions (CTEs)**:
   - `RankedMovies`: Ranks movies for each production year.
   - `CastInfoWithRoles`: Gathers cast information along with roles, creating a rank within each movie based on their order.
   - `MovieDetails`: Aggregates cast counts and creates a string list of actors with their roles for each movie.
   - `MostPopularTitles`: Ranks the most popular movies based on the number of distinct cast members.

2. **Main Query**:
   - Joins `MostPopularTitles` with the keywords, allowing for NULL checks via `COALESCE`.
   - Filters results where the cast count is above average and ensures there is a non-empty string for the cast list.
   - Categorizes movies as 'Top 10' or 'Below Top 10' based on their ranking and retrieves a limited number of results.

This query leverages several SQL constructs — ranks, aggregates, and joins — while demonstrating how to handle NULL values and generate insightful movie data.
