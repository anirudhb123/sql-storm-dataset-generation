WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        rk.rank,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL AND ak.name != ''
    GROUP BY 
        at.title, at.production_year
    WINDOW rk AS (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC)
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        ct.kind ILIKE '%Production%'
    GROUP BY 
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        rt.title,
        rt.production_year,
        cm.company_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CompanyMovies cm ON rt.production_year = cm.movie_id
    WHERE 
        rt.production_year >= 2000 AND 
        (rt.rank > 5 OR cm.company_count IS NULL)
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.company_count, 0) AS number_of_companies,
    CONCAT(fm.title, ' (', fm.production_year, ')') AS title_with_year,
    SUM(CASE 
            WHEN fm.production_year BETWEEN 2000 AND 2010 THEN 1 
            ELSE 0 
        END) OVER (PARTITION BY fm.production_year) AS movies_count_within_decade
FROM 
    FilteredMovies fm
WHERE 
    fm.title NOT LIKE '%-sequel%' 
ORDER BY 
    fm.production_year DESC, number_of_companies DESC;

This SQL query utilizes several constructs:

- Common Table Expressions (CTEs) are used to structure the query logically with `RankedTitles`, `CompanyMovies`, and `FilteredMovies`.
- The first CTE (`RankedTitles`) ranks titles based on the number of distinct actors involved, partitioned by production year.
- The second CTE (`CompanyMovies`) counts the distinct companies associated with movies that fall under production type.
- The filtered results aggregate both actors and company information while imposing conditions to exclude titles with certain keywords, providing a robust filtering mechanism.
- Window functions provide additional metrics based on the total count of movies produced within a particular decade.
- A use of aggregate functions like `STRING_AGG` to concatenate multiple actor names into a single string, showcasing string manipulation capabilities.
- NULL coercion is applied to handle potential missing company counts gracefully.
- The query also includes predicates that exhibit both straightforward and lower-level complexities, assisting in performance benchmarking by assessing how the database engine optimizes nested operations and different join types.
