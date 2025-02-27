WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        string_agg(DISTINCT c.name, ', ') AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    COALESCE(rm.production_year, 'Unknown') AS production_year,
    COALESCE(cd.companies, 'No companies listed') AS companies_involved,
    rm.actor_count,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    AVG(sub.rating) AS average_rating
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    (SELECT 
         movie_id, 
         AVG(rating) AS rating 
     FROM 
         movie_info 
     WHERE 
         info_type_id IN (SELECT id FROM info_type WHERE info = 'rating') 
     GROUP BY 
         movie_id) sub ON rm.movie_id = sub.movie_id
WHERE 
    rm.rank <= 5 
    AND (LOWER(rm.title) LIKE '%adventure%' OR rm.production_year > 2000)
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, cd.companies, rm.actor_count
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
