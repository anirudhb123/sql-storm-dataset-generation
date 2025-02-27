WITH RankedMovies AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),

TopTitles AS (
    SELECT
        title_id,
        title,
        production_year
    FROM
        RankedMovies
    WHERE 
        rank <= 3
),

MovieDetails AS (
    SELECT 
        tt.title,
        tt.production_year,
        a.name AS actor_name,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        (SELECT COUNT(*) FROM complete_cast c WHERE c.movie_id = tt.title_id) AS cast_size
    FROM 
        TopTitles tt
    LEFT JOIN 
        cast_info ci ON ci.movie_id = tt.title_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON tt.title_id = mk.movie_id
    GROUP BY 
        tt.title_id, tt.title, tt.production_year, a.name
)

SELECT 
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT md.actor_name, ', ') AS actors,
    COALESCE(md.keyword_count, 0) AS number_of_keywords,
    CASE 
        WHEN md.cast_size IS NULL THEN 'No cast information'
        ELSE CAST(md.cast_size AS TEXT)
    END AS cast_size_info
FROM 
    MovieDetails md
GROUP BY 
    md.title, md.production_year, md.keyword_count, md.cast_size
ORDER BY 
    md.production_year DESC,
    number_of_keywords DESC;
This query performs the following tasks:

1. **Common Table Expressions (CTEs)** are used to segment and rank the top titles based on their production year and the number of companies associated with them. 
   
2. The `RankedMovies` CTE identifies the top three movies for each production year by counting the unique companies involved and ranking them.

3. The `TopTitles` CTE filters the ranked movies to keep only the top three.

4. The `MovieDetails` CTE joins relevant tables to pull in information about each movie's title, production year, associated actors, the number of keywords, and the size of the complete cast.

5. The final `SELECT` statement aggregates actor names into a single string, counts keywords, and handles NULL values using `COALESCE` and a `CASE` statement for cast size information.

6. The `ORDER BY` clause sorts results by production year in descending order and then by the number of keywords in descending order. 

Overall, this query is a complex example of how to utilize various SQL features to derive meaningful insights from a multi-table database schema.
