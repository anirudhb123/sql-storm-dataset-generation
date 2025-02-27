WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        cast_count DESC
    LIMIT 10
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.aka_names,
    (SELECT 
        STRING_AGG(cn.name, ', ') 
     FROM 
        movie_companies mc 
     JOIN 
        company_name cn ON mc.company_id = cn.id 
     WHERE 
        mc.movie_id = rm.movie_id) AS companies_involved
FROM 
    RankedMovies rm;

In this query:
- We first create a Common Table Expression (CTE) called `RankedMovies` that selects movie details along with the count of cast members and aggregated alternate names (aka names) and keywords for movies produced from the year 2000 onward. 
- By joining multiple tables, we aggregate and filter the results.
- In the final SELECT statement, for each of the top 10 movies based on the number of cast members, we fetch the associated companies involved in producing those movies. 
- The output includes the movie's ID, title, production year, number of cast members, aka names, and the names of companies involved in each film.
