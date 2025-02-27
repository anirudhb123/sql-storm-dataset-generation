WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL 
        AND t.title NOT LIKE '%untitled%'
),

DirectorMovies AS (
    SELECT 
        c.movie_id,
        a.name AS director_name,
        COUNT(c.person_id) AS num_cast
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name ILIKE '%Smith%'
    GROUP BY 
        c.movie_id, a.name
),

CompanyStats AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        MAX(ct.kind) AS company_type,
        COUNT(*) AS num_movies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, co.name
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    dm.director_name,
    cs.company_name,
    cs.company_type,
    cs.num_movies,
    mk.keywords,
    COALESCE(dm.num_cast, 0) AS num_cast,
    CASE 
        WHEN dm.num_cast IS NULL THEN 'No cast found'
        WHEN dm.num_cast < 5 THEN 'Small cast'
        ELSE 'Large cast'
    END AS cast_size_description
FROM 
    RankedMovies rm
LEFT JOIN 
    DirectorMovies dm ON rm.movie_id = dm.movie_id
LEFT JOIN 
    CompanyStats cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.title_rank <= 3 
    AND (rm.production_year BETWEEN 2000 AND 2020 OR rm.production_year IS NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title;