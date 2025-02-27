WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies m ON t.id = m.movie_id
    JOIN 
        company_name cn ON m.company_id = cn.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.id, t.title, t.production_year
), 
TopRatedMovies AS (
    SELECT 
        r.movie_id, 
        r.title, 
        r.production_year, 
        r.company_count,
        r.company_names,
        r.keywords,
        ROW_NUMBER() OVER (ORDER BY r.company_count DESC) AS rank
    FROM 
        RankedMovies r
)
SELECT 
    tm.rank,
    tm.title,
    tm.production_year,
    tm.company_count,
    tm.company_names,
    STRING_AGG(DISTINCT c.role, ', ') AS roles
FROM 
    TopRatedMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    role_type c ON cc.role_id = c.id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.rank, tm.title, tm.production_year, tm.company_count, tm.company_names
ORDER BY 
    tm.rank;

This SQL query is designed to benchmark string processing involving multiple joins, aggregates, and window functions. It provides an overview of the top 10 movies produced since 2000 based on their associated number of companies, names of the companies, and their respective roles in the complete cast.
