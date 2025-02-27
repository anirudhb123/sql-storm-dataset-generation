WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT ci.id) AS total_cast,
        nt.name AS role_type
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        role_type nt ON nt.id = ci.role_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, nt.name
),
TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.companies,
        md.total_cast,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.total_cast DESC) AS rank
    FROM 
        MovieDetails md
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.keywords,
    tm.companies,
    tm.total_cast
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 5
ORDER BY 
    tm.production_year, tm.rank;

This query accomplishes the following:
1. Retrieves movie details including title, production year, associated keywords, company names, and total cast from multiple tables.
2. Filters movies released from the year 2000 onwards.
3. Groups the results by movie while aggregating keywords and company names.
4. Computes a rank for the top movies per production year based on the total cast count.
5. Selects the top 5 movies per year from this ranking.
6. Sorts the final result set by production year and rank.

