WITH RECURSIVE RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mci.note DESC) AS rank_by_note,
        COUNT(ci.id) OVER (PARTITION BY mt.id) AS total_cast_members,
        COALESCE(SUM(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE 1 END), 0) AS non_null_order_count
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast mci ON mt.id = mci.movie_id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL AND mt.kind_id IN (1, 3) -- Feature and Short films
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COALESCE(cn.name, 'Unknown') AS company_name,
        ct.kind AS company_type,
        GROUP_CONCAT(cn.country_code) AS country_codes
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COALESCE(SUM(CASE WHEN k.keyword IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_keywords
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id, 
    rm.title, 
    rm.rank_by_note,
    cd.company_name, 
    cd.company_type, 
    cd.country_codes, 
    ks.total_keywords,
    COALESCE(mci.status_id, 0) AS status_id
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id 
LEFT JOIN 
    complete_cast mci ON rm.movie_id = mci.movie_id AND mci.status_id IS NOT NULL 
LEFT JOIN 
    KeywordStats ks ON rm.movie_id = ks.movie_id
WHERE 
    rm.rank_by_note <= 5 -- Considering top 5 rated movies per year
    AND (cd.company_name <> 'Unknown' OR cd.company_type IS NULL) -- Filtering out unknown companies or those without types
ORDER BY 
    rm.production_year DESC, 
    rm.rank_by_note ASC;
