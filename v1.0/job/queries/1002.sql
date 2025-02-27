WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS total_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(cd.company_name, 'Unknown') AS production_company,
    COALESCE(cd.total_movies, 0) AS total_movies_by_company,
    (SELECT AVG(m.production_year) 
     FROM aka_title m 
     WHERE m.production_year IS NOT NULL) AS avg_production_year,
    (SELECT COUNT(DISTINCT k.keyword) 
     FROM movie_keyword mk 
     JOIN keyword k ON mk.keyword_id = k.id 
     WHERE mk.movie_id = rm.movie_id) AS unique_keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title ASC;
