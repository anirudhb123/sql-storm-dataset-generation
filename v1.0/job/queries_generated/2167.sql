WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title, 
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
CastInformation AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT CONCAT_WS(' ', ak.name) ORDER BY ak.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    tt.title, 
    tt.production_year,
    COALESCE(cm.company_name, 'Independent') AS company_name,
    COALESCE(cm.company_type, 'N/A') AS company_type,
    ci.cast_count,
    ci.cast_names
FROM 
    RankedTitles tt
LEFT JOIN 
    CompanyMovies cm ON tt.title_id = cm.movie_id
LEFT JOIN 
    CastInformation ci ON tt.title_id = ci.movie_id
WHERE 
    tt.title_rank <= 5
ORDER BY 
    tt.production_year DESC, 
    tt.title;
