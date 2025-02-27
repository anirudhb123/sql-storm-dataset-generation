WITH MovieDetails AS (
    SELECT 
        mt.id as movie_id,
        mt.title,
        mt.production_year,
        k.keyword,
        c.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY c.name) AS company_rank,
        COALESCE(SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year, k.keyword, c.name
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        MAX(cast_count) OVER (PARTITION BY production_year) AS max_cast_count,
        company_rank
    FROM 
        MovieDetails
    WHERE 
        company_rank = 1
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        max_cast_count
    FROM 
        TopMovies
    WHERE 
        max_cast_count > 5
)
SELECT 
    f.title,
    f.production_year,
    f.max_cast_count,
    CASE 
        WHEN f.max_cast_count = 0 THEN 'No cast listed'
        WHEN f.max_cast_count BETWEEN 1 AND 3 THEN 'Limited cast'
        WHEN f.max_cast_count BETWEEN 4 AND 10 THEN 'Decent cast'
        ELSE 'Extensive cast' 
    END AS cast_description
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, f.max_cast_count DESC;
