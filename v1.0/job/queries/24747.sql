WITH MovieRankings AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(ci.person_id) AS total_cast,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.title, mt.production_year
), 
CompanyAssociations AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
), 
KeywordsPerMovie AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(ca.companies, 'No Companies') AS companies,
        COALESCE(k.keywords, 'No Keywords') AS keywords,
        COALESCE(mr.total_cast, 0) AS total_cast,
        mr.rank_by_cast
    FROM 
        aka_title mt
    LEFT JOIN 
        CompanyAssociations ca ON mt.id = ca.movie_id
    LEFT JOIN 
        KeywordsPerMovie k ON mt.id = k.movie_id
    LEFT JOIN 
        MovieRankings mr ON mt.title = mr.movie_title AND mt.production_year = mr.production_year
)
SELECT 
    md.title AS Movie_Title,
    md.production_year AS Production_Year,
    md.companies,
    md.keywords,
    md.total_cast,
    md.rank_by_cast,
    CASE 
        WHEN md.total_cast > 10 THEN 'Large Cast'
        WHEN md.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    CASE 
        WHEN md.rank_by_cast IS NULL THEN 'Unranked'
        ELSE 'Ranked'
    END AS ranking_status
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2000 AND 2023
AND 
    (md.rank_by_cast = 1 OR md.companies NOT LIKE '%No Companies%')
ORDER BY 
    md.production_year DESC, 
    md.rank_by_cast;
