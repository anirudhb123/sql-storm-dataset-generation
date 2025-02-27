WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        string_agg(DISTINCT ak.name, ', ') AS aka_names,
        string_agg(DISTINCT c.nm) AS cast_names,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieStats AS (
    SELECT 
        movie_id,
        title, 
        production_year,
        aka_names,
        cast_names,
        keyword_count,
        RANK() OVER (ORDER BY keyword_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_id, 
    title, 
    production_year,
    aka_names,
    cast_names,
    keyword_count,
    rank
FROM 
    MovieStats
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, 
    keyword_count DESC;

This SQL query benchmarks string processing by aggregating names and keywords related to movies produced between 2000 and 2023. The query ranks the movies based on the number of keywords associated with them and limits the output to the top 10 results, which emphasizes the intricacies of handling string data in a rich relational schema.
