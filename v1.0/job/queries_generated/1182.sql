WITH MovieRankings AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
RecentMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COALESCE(mnk.keywords_count, 0) AS keywords_count
    FROM 
        aka_title a
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(*) AS keywords_count
        FROM 
            movie_keyword
        GROUP BY 
            movie_id
    ) AS mnk ON a.id = mnk.movie_id
    WHERE 
        a.production_year >= (SELECT MAX(production_year) - 5 FROM aka_title)
),
CompanyInfo AS (
    SELECT 
        mc.movie_id, 
        ARRAY_AGG(DISTINCT cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        rm.title AS movie_title,
        rm.production_year,
        rm.cast_count,
        cm.companies,
        rm.keywords_count
    FROM 
        MovieRankings rm
    LEFT JOIN 
        RecentMovies r ON rm.title = r.title AND rm.production_year = r.production_year
    LEFT JOIN 
        CompanyInfo cm ON rm.title = (SELECT title FROM aka_title WHERE id = rm.movie_title)
    WHERE 
        rm.rank <= 10
)
SELECT 
    movie_title, 
    production_year,
    cast_count,
    companies,
    keywords_count
FROM 
    FinalResults
ORDER BY 
    production_year DESC, cast_count DESC;
