WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'No Actors') AS actors,
        COALESCE(STRING_AGG(DISTINCT kw.keyword, ', '), 'No Keywords') AS keywords
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    GROUP BY 
        t.id
), CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
), CompleteMovieDetails AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        md.actors,
        ci.companies
    FROM 
        MovieDetails AS md
    LEFT JOIN 
        CompanyInfo AS ci ON md.title_id = ci.movie_id
), RankedMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY title ASC) AS rn
    FROM 
        CompleteMovieDetails
    WHERE 
        production_year IS NOT NULL
)
SELECT 
    title,
    production_year,
    actors,
    companies,
    CASE 
        WHEN rn <= 5 THEN 'Top 5 Movies of the Year'
        ELSE 'Other Movies'
    END AS movie_category
FROM 
    RankedMovies
WHERE 
    actors IS NOT NULL AND companies IS NOT NULL
ORDER BY 
    production_year DESC, title ASC;
