
WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        at.kind_id,
        ROW_NUMBER() OVER (PARTITION BY at.kind_id ORDER BY at.production_year DESC) AS rank
    FROM 
        aka_title at
    WHERE 
        at.production_year BETWEEN 2000 AND 2023
),
MovieCompaniesWithTypes AS (
    SELECT 
        mc.movie_id,
        mc.company_id,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
CompleteCastInfo AS (
    SELECT 
        cc.movie_id,
        STRING_AGG(CONCAT(p.name, ' as ', rt.role), ', ') AS full_cast
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        name p ON ci.person_id = p.id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        cc.movie_id
),
MoviesWithDetails AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        mk.keyword_count,
        mcwt.company_type,
        cci.full_cast,
        rt.rank
    FROM 
        RankedTitles rt
    JOIN 
        KeywordCounts mk ON rt.title_id = mk.movie_id
    JOIN 
        MovieCompaniesWithTypes mcwt ON rt.title_id = mcwt.movie_id
    LEFT JOIN 
        CompleteCastInfo cci ON rt.title_id = cci.movie_id
)
SELECT 
    mwd.title,
    mwd.production_year,
    mwd.keyword_count,
    mwd.company_type,
    mwd.full_cast
FROM 
    MoviesWithDetails mwd
WHERE 
    mwd.rank <= 5
ORDER BY 
    mwd.production_year DESC, 
    mwd.title;
