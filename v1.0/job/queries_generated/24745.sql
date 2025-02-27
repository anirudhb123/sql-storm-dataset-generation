WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT n.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name n ON c.person_id = n.person_id
    GROUP BY 
        c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, '; ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(cd.cast_names, 'N/A') AS cast_names,
    COALESCE(comp.companies, 'No company info') AS companies,
    COALESCE(comp.company_types, 'No type info') AS company_types,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = rm.movie_id) AS info_count,
    CASE 
        WHEN rm.production_year < 2000 THEN 'Old'
        WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Recent'
        ELSE 'New'
    END AS movie_age_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CompanyDetails comp ON rm.movie_id = comp.movie_id
WHERE 
    rm.title_rank <= 10
ORDER BY 
    rm.production_year DESC,
    rm.title ASC;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - **RankedMovies**: Ranks movies based on their production year and title using `ROW_NUMBER()`.
   - **CastDetails**: Aggregates cast information for each movie, counting distinct cast members and concatenating names.
   - **CompanyDetails**: Aggregates company information related to each movie, concatenating company names and types.
   
2. **Main Query**: Joins the CTEs and selects relevant movie data with left joins to accommodate movies that may have missing cast or company information.

3. **COALESCE**: Used to handle NULL values gracefully, providing default text where applicable.

4. **Subquery**: Counts the number of `movie_info` entries per movie.

5. **CASE Statement**: Classifies movies into categories based on their production year.

6. **WHERE Clause**: Filters results to include only the top 10 titles for each production year.

7. **ORDER BY Clause**: Organizes the final results first by production year, then by title. 

This query showcases multiple SQL features while ensuring that it remains complex and interesting, capturing various edge cases and NULL handling.
