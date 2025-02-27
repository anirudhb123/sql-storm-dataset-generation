WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mi.info_type_id) AS info_count
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        cast_names,
        company_count,
        info_count,
        ROW_NUMBER() OVER (PARTITION BY keyword ORDER BY company_count DESC, info_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    movie_id,
    title,
    production_year,
    keyword,
    cast_names,
    company_count,
    info_count
FROM 
    TopMovies
WHERE 
    rank = 1
ORDER BY 
    production_year DESC, title;
