WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        COUNT(DISTINCT kw.id) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        keyword_count, 
        company_count
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 10  -- Get top 10 movies by cast count per year
),
FullDetails AS (
    SELECT 
        tm.title, 
        tm.production_year, 
        tm.cast_count,
        tm.keyword_count,
        tm.company_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        tm.title, tm.production_year, tm.cast_count, tm.keyword_count, tm.company_count 
)
SELECT 
    title, 
    production_year, 
    cast_count, 
    keyword_count, 
    company_count, 
    actors, 
    companies, 
    keywords
FROM 
    FullDetails
ORDER BY 
    production_year DESC, 
    cast_count DESC;
