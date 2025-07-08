
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS production_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        MAX(ct.kind) AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
NullCheck AS (
    SELECT 
        cm.movie_id,
        COUNT(*) AS null_count
    FROM 
        cast_info ci
    LEFT JOIN 
        movie_companies cm ON ci.movie_id = cm.movie_id
    WHERE 
        ci.person_id IS NULL
    GROUP BY 
        cm.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    cd.companies,
    cd.company_type,
    COALESCE(nc.null_count, 0) AS num_nulls,
    CASE 
        WHEN rm.production_rank <= 3 THEN 'Top Movie'
        ELSE 'Other'
    END AS movie_rank_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    NullCheck nc ON rm.movie_id = nc.movie_id
WHERE 
    rm.production_year = (SELECT MAX(production_year) FROM aka_title)
ORDER BY 
    rm.cast_count DESC, rm.title ASC
LIMIT 10;
