WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS cast_count,
        AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order,
        DENSE_RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        MAX(CASE WHEN ct.kind = 'Distributor' THEN cn.name END) AS distributor_name
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
ExtendedMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.avg_order,
        cd.company_names,
        cd.distributor_name,
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = rm.movie_id) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyDetails cd ON rm.movie_id = cd.movie_id 
)
SELECT 
    emi.movie_id,
    emi.title,
    emi.production_year,
    emi.cast_count,
    emi.avg_order,
    emi.company_names,
    emi.distributor_name,
    emi.keyword_count,
    CASE
        WHEN emi.keyword_count > 5 THEN 'Highly Tagged'
        WHEN emi.keyword_count BETWEEN 3 AND 5 THEN 'Moderately Tagged'
        ELSE 'Low Tags'
    END AS tagline,
    COALESCE((SELECT STRING_AGG(DISTINCT p.info, ', ') 
              FROM person_info p 
              WHERE p.person_id IN (
                  SELECT c.person_id 
                  FROM cast_info c 
                  WHERE c.movie_id = emi.movie_id)
              AND p.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Biography', 'Awards'))), 
              'No Info') AS personal_info
FROM 
    ExtendedMovieInfo emi
WHERE 
    emi.cast_count > (
        SELECT AVG(cast_count) FROM RankedMovies
    ) 
    AND emi.production_year IS NOT NULL
    AND emi.distributor_name IS NOT NULL
ORDER BY 
    emi.production_year DESC,
    emi.cast_count DESC;
