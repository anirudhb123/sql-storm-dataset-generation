
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        kc.kind AS movie_kind,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        kind_type kc ON t.kind_id = kc.id
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        SUM(CASE 
            WHEN r.role = 'lead' THEN 1 
            ELSE 0 
        END) AS lead_cast_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS unique_production_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
MovieStatistics AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.movie_kind,
        COALESCE(cd.total_cast, 0) AS total_cast,
        COALESCE(cd.lead_cast_count, 0) AS lead_cast_count,
        COALESCE(cd.total_cast, 0) - COALESCE(cd.lead_cast_count, 0) AS supporting_cast_count,
        COALESCE(co.unique_production_companies, 0) AS unique_production_companies,
        rm.rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_title = (SELECT title FROM aka_title WHERE movie_id = cd.movie_id LIMIT 1)
    LEFT JOIN 
        CompanyDetails co ON rm.movie_title = (SELECT title FROM aka_title WHERE movie_id = co.movie_id LIMIT 1)
)
SELECT 
    ms.movie_title,
    ms.production_year,
    ms.movie_kind,
    ms.total_cast,
    ms.lead_cast_count,
    ms.supporting_cast_count,
    ms.unique_production_companies,
    CASE 
        WHEN ms.total_cast = 0 THEN 'No cast info available'
        WHEN ms.unique_production_companies > 5 THEN 'Major Production'
        WHEN ms.supporting_cast_count = 0 THEN 'Lone hero'
        ELSE 'Standard release'
    END AS release_category
FROM 
    MovieStatistics ms
WHERE 
    ms.rank <= 10 
ORDER BY 
    ms.production_year DESC, ms.movie_title 
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;
