WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
        AND k.keyword IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        company_name,
        movie_keyword
    FROM 
        RankedMovies
    WHERE 
        rank = 1
),
MovieInfo AS (
    SELECT 
        fm.movie_title,
        fm.production_year,
        fm.company_name,
        fm.movie_keyword,
        mi.info AS additional_info
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_info mi ON fm.movie_title = mi.info
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
)

SELECT 
    movie_title,
    production_year,
    company_name,
    movie_keyword,
    COALESCE(additional_info, 'No additional info available') AS budget_info
FROM 
    MovieInfo
ORDER BY 
    production_year DESC, 
    movie_title;
