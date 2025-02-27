WITH RankedMovies AS (
    SELECT
        at.title,
        at.production_year,
        COUNT(cm.company_id) AS production_company_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(cm.company_id) DESC) AS rn
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        at.title, at.production_year
),
TopRankedMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.production_company_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
),
CastDetails AS (
    SELECT 
        ak.name,
        at.title,
        ci.note AS role_note,
        ci.nr_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
)
SELECT 
    trm.title,
    trm.production_year,
    trm.production_company_count,
    COALESCE(STRING_AGG(cd.name, ', ') FILTER (WHERE cd.nr_order IS NOT NULL), 'No Cast') AS cast_names,
    COUNT(DISTINCT cd.role_note) AS unique_role_count
FROM 
    TopRankedMovies trm
LEFT JOIN 
    CastDetails cd ON trm.title = cd.title
GROUP BY 
    trm.title, trm.production_year, trm.production_company_count
ORDER BY 
    trm.production_year DESC, trm.production_company_count DESC;
