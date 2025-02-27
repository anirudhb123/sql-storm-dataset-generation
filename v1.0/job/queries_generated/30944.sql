WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000
), 
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    R.movie_id,
    R.movie_title,
    R.production_year,
    CD.cast_count,
    CD.cast_names,
    MK.keywords,
    COALESCE(MC.companies, 'No companies listed') AS production_companies,
    CASE 
        WHEN R.production_year < 2010 THEN 'Before 2010'
        ELSE '2010 or later'
    END AS year_category
FROM 
    RecursiveMovieCTE AS R
LEFT JOIN 
    CastDetails AS CD ON R.movie_id = CD.movie_id
LEFT JOIN 
    MovieKeywords AS MK ON R.movie_id = MK.movie_id
LEFT JOIN 
    MovieCompanies AS MC ON R.movie_id = MC.movie_id
WHERE 
    R.title_rank <= 5
ORDER BY 
    R.production_year DESC, 
    R.movie_title;
