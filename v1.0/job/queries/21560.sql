
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS rank_title,
        COUNT(*) OVER(PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%movie%')
), MovieCast AS (
    SELECT 
        cm.movie_id,
        STRING_AGG(CONCAT(a.name, ' (', r.role, ')'), ', ') AS cast
    FROM 
        cast_info cm
    JOIN 
        aka_name a ON cm.person_id = a.person_id
    JOIN 
        role_type r ON cm.role_id = r.id
    GROUP BY 
        cm.movie_id
), CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
), MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'budget' THEN mi.info END) AS budget,
        MAX(CASE WHEN it.info = 'boxoffice' THEN mi.info END) AS boxoffice,
        MAX(CASE WHEN it.info = 'rating' THEN mi.info END) AS rating
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
), AggregateData AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mc.cast,
        cd.company_name,
        cd.company_type,
        mi.budget,
        mi.boxoffice,
        mi.rating,
        RANK() OVER (ORDER BY COALESCE(CAST(mi.boxoffice AS numeric), 0) DESC) AS boxoffice_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCast mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        CompanyDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        MovieInfo mi ON rm.movie_id = mi.movie_id
)
SELECT 
    ad.title,
    ad.production_year,
    ad.cast,
    ad.company_name,
    ad.company_type,
    ad.budget,
    ad.boxoffice,
    ad.boxoffice_rank,
    CASE 
        WHEN ad.boxoffice IS NULL AND ad.budget IS NULL THEN 'No financial data'
        WHEN ad.boxoffice IS NULL THEN 'Box office data missing'
        WHEN ad.budget IS NULL THEN 'Budget data missing'
        ELSE 'Complete financial data'
    END AS financial_data_status
FROM 
    AggregateData ad
WHERE 
    ad.boxoffice_rank <= 10
ORDER BY 
    ad.boxoffice_rank, ad.production_year DESC
LIMIT 20;
