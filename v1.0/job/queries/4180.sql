
WITH MovieRanked AS (
    SELECT 
        at.title, 
        at.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
), 
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        MovieRanked 
    WHERE 
        rank_per_year <= 5
), 
MovieDetails AS (
    SELECT 
        tm.title, 
        tm.production_year, 
        STRING_AGG(DISTINCT an.name, ', ') AS actors
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
    LEFT JOIN 
        aka_name an ON an.person_id = cc.subject_id
    GROUP BY 
        tm.title, tm.production_year
), 
CompanyInfo AS (
    SELECT 
        at.title,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        aka_title at
    JOIN 
        movie_companies mc ON at.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
), 
CombinedInfo AS (
    SELECT 
        md.title, 
        md.production_year, 
        md.actors, 
        ci.company_name, 
        ci.company_type
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyInfo ci ON md.title = ci.title
)
SELECT 
    ci.title,
    ci.production_year,
    COALESCE(ci.actors, 'No Cast Available') AS actors,
    COALESCE(ci.company_name, 'Independent') AS production_company,
    COALESCE(ci.company_type, 'N/A') AS company_type
FROM 
    CombinedInfo ci
ORDER BY 
    ci.production_year DESC, ci.title;
