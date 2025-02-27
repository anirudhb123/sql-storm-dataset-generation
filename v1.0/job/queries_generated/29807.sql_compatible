
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT co.name, ', ') AS production_companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name ak ON t.id = ak.id 
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id 
    LEFT JOIN 
        company_name co ON mc.company_id = co.id 
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id 
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id 
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id 
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        aka_names,
        production_companies,
        keywords,
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.aka_names,
    tm.production_companies,
    tm.keywords,
    tm.cast_count
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.cast_count DESC;
