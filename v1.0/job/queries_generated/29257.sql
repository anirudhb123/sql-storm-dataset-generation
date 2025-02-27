WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        ARRAY_AGG(DISTINCT a.name) AS cast_list,
        COUNT(DISTINCT mc.company_id) AS production_companies_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT a.id) DESC) AS rank_by_cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.kind_id,
        rm.cast_list,
        rm.production_companies_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_cast_count <= 5 
        AND rm.production_year >= 2000
)
SELECT 
    f.movie_title,
    f.production_year,
    k.keyword AS genre,
    f.production_companies_count,
    f.cast_list
FROM 
    FilteredMovies f
JOIN 
    title t ON f.movie_title = t.title AND f.production_year = t.production_year
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
ORDER BY 
    f.production_year DESC, 
    f.production_companies_count DESC;

### Explanation:
- **With Clause**: Two common table expressions (CTEs) are defined:
  - `RankedMovies`: Computes a ranked list of movies grouped by production year based on the count of distinct cast members and aggregates the cast names.
  - `FilteredMovies`: Filters the movies from `RankedMovies` that have 5 or fewer cast members and were produced after 2000.
  
- **Final Select Statement**: Retrieves movie titles, production years, associated genres, production company counts, and cast lists by joining with the `title`, `movie_keyword`, and `keyword` tables.

- **Ordering**: The final result set is ordered first by production year (most recent first) and then by the number of production companies, descending.
