WITH RankedMovies AS (
    SELECT 
        t.imdb_index AS movie_index,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COALESCE(m.comp_count, 0) DESC, t.title) AS rank_in_year
    FROM 
        aka_title t
    LEFT JOIN 
        (SELECT 
            movie_id, 
            COUNT(company_id) AS comp_count
        FROM 
            movie_companies 
        GROUP BY 
            movie_id) m ON t.id = m.movie_id
    WHERE 
        t.production_year IS NOT NULL
),

TopMovies AS (
    SELECT 
        rm.movie_index, 
        rm.movie_title, 
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_in_year <= 5
),

MovieDetails AS (
    SELECT 
        tm.movie_index,
        tm.movie_title,
        ARRAY_AGG(DISTINCT CONCAT(c.name, ' (', rt.role, ')')) AS cast,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON ci.movie_id = (SELECT id FROM aka_title WHERE imdb_index = tm.movie_index)
    LEFT JOIN 
        char_name c ON c.imdb_id = ci.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE imdb_index = tm.movie_index)
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        tm.movie_index, tm.movie_title
)

SELECT 
    md.movie_title,
    md.production_year,
    COALESCE(md.cast, '{}') AS cast_list,
    COALESCE(md.keywords, '{}') AS keyword_list,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = (SELECT id FROM aka_title WHERE imdb_index = md.movie_index) AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')) AS awards_count
FROM 
    TopMovies tm
LEFT JOIN 
    MovieDetails md ON md.movie_index = tm.movie_index
ORDER BY 
    tm.production_year DESC, 
    md.movie_title ASC;


This SQL query is designed to extract performance benchmarking data related to movies while using various advanced SQL constructs. 

1. **CTEs (Common Table Expressions)** are used to create structured temporary result sets that facilitate complex calculations: 
   - `RankedMovies` computes the rank of movies based on the count of associated movie companies per production year.
   - `TopMovies` extracts the top 5 movies per year.
   - `MovieDetails` aggregates cast information and keywords for each of the top movies.

2. **Outer joins** are leveraged to gather all relevant data including those movies with no associated companies, casts, or keywords.

3. **Correlated subqueries** are applied to dynamically get IDs based on the `imdb_index`, ensuring that we stay within the context of our derived results.

4. **Array and string functions** are used to construct a comma-separated list of cast members and keywords.

5. **COALESCE** and NULL logic handle cases where movies may lack associated data, defaulting to empty arrays.

6. The final result set is ordered by production year in descending order and movie title in ascending order to provide structured readability. 

This query effectively demonstrates how to intricately weave together various components of SQL to address a performance benchmarking requirement.
