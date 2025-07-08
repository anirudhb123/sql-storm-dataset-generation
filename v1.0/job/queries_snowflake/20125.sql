
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CastInfoAgg AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(ci.nr_order) AS max_order,
        LISTAGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_type_id) AS company_type_count,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(k.keywords_list, 'No Keywords') AS keywords,
    COALESCE(c.total_cast, 0) AS total_cast_members,
    COALESCE(c.cast_names, 'No Cast') AS cast_names,
    COALESCE(m.company_names, 'No Companies') AS companies_involved,
    COALESCE(m.company_type_count, 0) AS types_of_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords k ON rm.title_id = k.movie_id
LEFT JOIN 
    CastInfoAgg c ON rm.title_id = c.movie_id
LEFT JOIN 
    MovieCompanies m ON rm.title_id = m.movie_id
WHERE 
    rm.production_year >= 2000 
    AND (k.keywords_list IS NOT NULL OR c.total_cast > 5)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
