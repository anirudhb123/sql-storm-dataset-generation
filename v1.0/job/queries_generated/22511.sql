WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mk.keyword, 'No keywords') AS keyword,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        LAG(t.production_year) OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS previous_year
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
CompleteMovieInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keyword,
        md.cast_count,
        md.actors,
        cd.companies,
        cd.company_count,
        CASE 
            WHEN md.previous_year < md.production_year THEN 'Newer Release'
            WHEN md.previous_year IS NULL THEN 'First Release'
            ELSE 'Older Release'
        END AS release_status
    FROM 
        MovieDetails AS md
    LEFT JOIN 
        CompanyDetails AS cd ON md.movie_id = cd.movie_id
),
DistinctRoleCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.role_id) AS unique_roles
    FROM 
        cast_info AS c 
    GROUP BY 
        c.movie_id
)

SELECT 
    mi.movie_id,
    mi.title,
    mi.production_year,
    mi.keyword,
    mi.cast_count,
    mi.actors,
    mi.companies,
    mi.company_count,
    mi.release_status,
    drc.unique_roles,
    CASE 
        WHEN mi.cast_count > 10 AND drc.unique_roles > 5 THEN 'Large Ensemble'
        ELSE 'Standard Cast'
    END AS cast_size_category
FROM 
    CompleteMovieInfo AS mi
LEFT JOIN 
    DistinctRoleCounts AS drc ON mi.movie_id = drc.movie_id
WHERE 
    mi.release_status <> 'Older Release' 
    AND mi.company_count > 1 
    AND mi.keyword NOT LIKE '%unclassified%'
ORDER BY 
    mi.production_year DESC, 
    mi.title ASC
LIMIT 50;

### Explanation:
- **CTEs** are utilized to break down the query into manageable components, helping to aggregate movie details and company information.
- **String aggregation** is used to compile a list of actor names and companies related to each movie.
- **Window functions** like `LAG` are used to track the production year of movies to determine their status relative to previous releases.
- A `CASE` statement is used to classify movies based on release status and cast size.
- Complex predicates and excluding `NULL` logic are part of filtering, ensuring meaningful data is displayed.
- The overall structure aims to showcase performance by joining multiple large datasets, ensuring an elaborate evaluation of movie characteristics.
