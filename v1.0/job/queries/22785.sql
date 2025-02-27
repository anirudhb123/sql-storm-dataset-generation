
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        at.kind_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year, at.kind_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS company_names,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        cd.company_names,
        cd.company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyDetails cd ON rm.production_year IS NOT NULL AND rm.production_year BETWEEN 1990 AND 2020
    WHERE 
        rm.actor_count > 5
    AND 
        EXISTS (
            SELECT 1 FROM movie_info mi 
            WHERE mi.movie_id = rm.kind_id 
            AND mi.info LIKE '%Oscar%'
        )
)

SELECT 
    fm.title,
    fm.production_year,
    fm.actor_count,
    COALESCE(fm.company_names, 'Not Listed') AS company_names,
    fm.company_type,
    RANK() OVER (ORDER BY fm.actor_count DESC) AS overall_rank
FROM 
    FilteredMovies fm
WHERE 
    (fm.production_year IS NULL OR fm.production_year > 2000)
ORDER BY 
    overall_rank, fm.production_year DESC;
