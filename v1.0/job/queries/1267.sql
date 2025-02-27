WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(CAST(m.production_year AS VARCHAR), 'Unknown') AS production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS additional_info
    FROM 
        movie_info mi
    WHERE 
        mi.note IS NULL
    GROUP BY 
        mi.movie_id
),
RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_count,
        md.actor_names,
        cd.company_names,
        cd.company_count,
        mi.additional_info,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.actor_count DESC) AS rank
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.movie_id = cd.movie_id
    LEFT JOIN 
        MovieInfo mi ON md.movie_id = mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.actor_names,
    rm.company_names,
    rm.company_count,
    rm.additional_info,
    rm.rank
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 5 
    AND (rm.company_count > 0 OR rm.additional_info IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC;
