WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
), 
MovieRanking AS (
    SELECT 
        movie_title, 
        production_year,
        kind_id,
        cast_count,
        actors,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY kind_id ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    mr.movie_title,
    mr.production_year,
    kt.kind AS category,
    mr.cast_count,
    mr.actors,
    mr.keywords,
    mr.rank
FROM 
    MovieRanking mr
JOIN 
    kind_type kt ON mr.kind_id = kt.id
WHERE 
    mr.rank <= 5
ORDER BY 
    mr.kind_id, 
    mr.rank;

This SQL query does the following:
1. Creates a Common Table Expression (CTE) `RankedMovies` to gather essential details about movies produced after 2000, including their titles, production years, kind IDs, cast counts, and associated keywords.
2. It aggregates the names of actors and keywords for each movie.
3. Uses another CTE `MovieRanking` to rank these movies within their respective categories based on the count of cast members.
4. Finally, it selects the top 5 movies from each category, including their details, and orders them first by category and then by rank.
