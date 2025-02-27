WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY b.nr_order DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info b ON a.id = b.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        c.name, 
        ct.kind AS company_type, 
        mc.movie_id
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
ExtendedMovieInfo AS (
    SELECT 
        m.title, 
        m.production_year, 
        COUNT(DISTINCT k.keyword) AS keyword_count,
        COALESCE(com.company_type, 'No Company') AS company_type
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        CompanyDetails com ON m.id = com.movie_id
    GROUP BY 
        m.title, m.production_year, com.company_type
)
SELECT 
    em.title, 
    em.production_year, 
    em.keyword_count, 
    CASE 
        WHEN em.keyword_count > 5 THEN 'Popular'
        WHEN em.keyword_count BETWEEN 3 AND 5 THEN 'Moderate'
        ELSE 'Less Popular'
    END AS popularity,
    COALESCE(COUNT(ci.id), 0) AS cast_count
FROM 
    ExtendedMovieInfo em
LEFT JOIN 
    complete_cast cc ON em.title = cc.id  -- Assuming title and complete_cast.id are comparable for this example.
LEFT JOIN 
    cast_info ci ON cc.movie_id = ci.movie_id
WHERE 
    em.production_year = (SELECT MAX(production_year) FROM aka_title WHERE production_year IS NOT NULL)
GROUP BY 
    em.title, 
    em.production_year, 
    em.keyword_count
HAVING 
    COUNT(ci.id) > 0
ORDER BY 
    em.production_year DESC, 
    em.keyword_count DESC;
