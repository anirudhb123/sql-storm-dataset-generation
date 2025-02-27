WITH MovieDetails AS (
    SELECT 
        title.title AS movie_title,
        title.production_year,
        string_agg(DISTINCT aka_name.name, ', ') AS actor_names,
        COUNT(DISTINCT movie_keyword.keyword_id) AS keyword_count,
        COUNT(DISTINCT company_name.name) AS company_count
    FROM 
        title 
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    JOIN 
        complete_cast ON title.id = complete_cast.movie_id
    JOIN 
        cast_info ON complete_cast.subject_id = cast_info.person_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    LEFT JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    WHERE 
        title.production_year >= 2000
    GROUP BY 
        title.title, title.production_year
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS total_keywords
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_names,
    COALESCE(ks.total_keywords, 0) AS total_keywords,
    COALESCE(cs.total_companies, 0) AS total_companies
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordStats ks ON md.movie_title = (SELECT title FROM title WHERE id = ks.movie_id)
LEFT JOIN 
    CompanyStats cs ON md.movie_title = (SELECT title FROM title WHERE id = cs.movie_id)
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
