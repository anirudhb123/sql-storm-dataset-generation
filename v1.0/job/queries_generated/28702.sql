WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.company_id) AS company_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        company_name co ON m.company_id = co.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
), 
ranked_cast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        COUNT(DISTINCT ci.id) AS cast_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        c.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.company_count,
    rm.keyword_count,
    rm.companies,
    rm.keywords,
    rc.cast_names,
    rc.cast_count
FROM 
    ranked_movies rm
LEFT JOIN 
    ranked_cast rc ON rm.movie_id = rc.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.keyword_count DESC, 
    rc.cast_count DESC
LIMIT 100;

This SQL query constructs two Common Table Expressions (CTEs): 
1. `ranked_movies`: It aggregates movies produced between the years 2000 and 2023, counting distinct companies and keywords associated with each movie, and formats the names of companies and keywords into comma-separated strings.
2. `ranked_cast`: It aggregates cast information for each movie, counting distinct cast members and formatting their names into a string.

The main query then joins these two CTEs to produce a final result set that includes relevant movie details, ordered by production year, keyword count, and cast count, limiting it to 100 results for benchmarking purposes.
