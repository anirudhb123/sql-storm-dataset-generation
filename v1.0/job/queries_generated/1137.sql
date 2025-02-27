WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COALESCE(c.role, 'Unknown') AS role,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn
    FROM aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    WHERE a.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN title m ON mc.movie_id = m.id
    GROUP BY m.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(cd.company_count, 0) AS total_companies,
    COALESCE(cd.company_names, 'None') AS companies,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN rm.role = 'Unknown' THEN 'Role not specified'
        ELSE rm.role 
    END AS display_role
FROM RankedMovies rm
LEFT JOIN CompanyDetails cd ON rm.title = cd.movie_id
LEFT JOIN MovieKeywords mk ON rm.title = mk.movie_id
WHERE rm.rn <= 5
ORDER BY rm.production_year DESC, rm.title ASC;
