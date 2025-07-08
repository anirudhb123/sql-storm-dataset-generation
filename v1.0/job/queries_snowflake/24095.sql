
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_per_year,
        t.id AS movie_id
    FROM 
        aka_title t
        LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, 
        t.production_year, 
        t.id
),
PopularActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
        JOIN cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, 
        a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
        JOIN company_name c ON mc.company_id = c.id
        JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id, 
        c.name, 
        ct.kind
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        LISTAGG(mi.info, ', ') AS info_details
    FROM 
        movie_info mi
    WHERE 
        mi.info IS NOT NULL
    GROUP BY 
        mi.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    pa.name AS popular_actor,
    pa.movie_count,
    cd.company_name,
    cd.company_type,
    mi.info_details
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularActors pa ON pa.person_id IN (
        SELECT 
            ci.person_id 
        FROM 
            cast_info ci
        WHERE 
            ci.movie_id = rm.movie_id
    )
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank_per_year <= 3 
    AND (cd.company_count IS NULL OR cd.company_count > 1) 
    AND (rm.production_year IS NOT NULL AND rm.production_year BETWEEN 2000 AND 2023)
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC, 
    pa.movie_count DESC;
