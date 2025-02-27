WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularCompanies AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name, 
        COUNT(DISTINCT c.id) AS movies_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        aka_title mt ON mc.movie_id = mt.id
    LEFT JOIN 
        cast_info c ON mt.id = c.movie_id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id, cn.name
    HAVING 
        COUNT(DISTINCT mc.movie_id) > 1
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(pc.company_name, 'No Company') AS company_name,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = rm.movie_id AND mi.info_type_id = 1) AS info_count
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularCompanies pc ON rm.movie_id = pc.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
