WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        string_agg(DISTINCT a.name, ', ') AS actors,
        count(DISTINCT kc.id) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        t.production_year >= 2000
        AND (cn.country_code IS NULL OR cn.country_code <> 'USA')
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedMovies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank
    FROM 
        MovieDetails
),
TopMovies AS (
    SELECT 
        *,
        COUNT(*) OVER () AS total_movies
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    title, 
    production_year, 
    actors, 
    total_movies
FROM 
    TopMovies
ORDER BY 
    production_year DESC, 
    rank;
