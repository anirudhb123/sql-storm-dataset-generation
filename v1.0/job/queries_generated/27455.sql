WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        ARRAY_AGG(DISTINCT ak.name) AS cast_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        movie_title,
        production_year,
        num_cast,
        cast_names,
        keywords,
        company_names,
        rank
    FROM 
        RankedMovies
    WHERE 
        rank <= 5  -- Get top 5 movies per year
)
SELECT 
    tm.production_year,
    STRING_AGG(tm.movie_title, ' | ') AS top_movies,
    STRING_AGG(tm.cast_names, ' ; ') AS all_casts,
    STRING_AGG(tm.keywords, ' ; ') AS all_keywords,
    STRING_AGG(tm.company_names, ' ; ') AS all_companies
FROM 
    TopMovies tm
GROUP BY 
    tm.production_year
ORDER BY 
    tm.production_year DESC;
