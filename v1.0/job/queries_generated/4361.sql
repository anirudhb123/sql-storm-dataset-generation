WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.num_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    f.title,
    f.production_year,
    f.num_cast,
    COALESCE(k.keyword, 'N/A') AS keyword,
    COALESCE(company.name, 'Independent') AS company_name
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_keyword mk ON f.title = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON f.title = mc.movie_id
LEFT JOIN 
    company_name company ON mc.company_id = company.id 
WHERE 
    f.production_year BETWEEN 2000 AND 2020
    AND f.num_cast > 2
ORDER BY 
    f.production_year, f.num_cast DESC;
