
WITH MovieKeywordCounts AS (
    SELECT 
        mt.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.id
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
CompleteMovieCast AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        cc.movie_id
),
FinalMovieData AS (
    SELECT 
        mt.title,
        mt.production_year,
        mkc.keyword_count,
        cmi.company_names,
        cmi.total_companies,
        cmc.total_cast,
        cmc.cast_names
    FROM 
        aka_title mt
    LEFT JOIN 
        MovieKeywordCounts mkc ON mt.id = mkc.movie_id
    LEFT JOIN 
        CompanyMovieInfo cmi ON mt.id = cmi.movie_id
    LEFT JOIN 
        CompleteMovieCast cmc ON mt.id = cmc.movie_id
    WHERE 
        mt.production_year >= 2000 AND 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
)
SELECT 
    title, 
    production_year, 
    COALESCE(keyword_count, 0) AS keyword_count, 
    COALESCE(company_names, 'None') AS company_names, 
    COALESCE(total_companies, 0) AS total_companies, 
    COALESCE(total_cast, 0) AS total_cast, 
    COALESCE(cast_names, 'None') AS cast_names
FROM 
    FinalMovieData
ORDER BY 
    production_year DESC, 
    title
LIMIT 100;
