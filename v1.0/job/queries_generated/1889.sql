WITH RecursiveMovieStats AS (
    SELECT 
        a.title AS movie_title,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(m.production_year) AS avg_year,
        MAX(m.production_year) AS latest_year
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        movie_info m ON a.id = m.movie_id
    WHERE 
        m.info_type_id = (SELECT id FROM info_type WHERE info = 'duration')
    GROUP BY 
        a.title
),
KeywordStats AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        mc.note IS NULL
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        r.movie_title,
        r.total_cast,
        r.avg_year,
        r.latest_year,
        k.keywords,
        c.companies
    FROM 
        RecursiveMovieStats r
    LEFT JOIN 
        KeywordStats k ON r.movie_title = (SELECT title FROM aka_title WHERE id = k.movie_id)
    LEFT JOIN 
        CompanyStats c ON r.movie_title = (SELECT title FROM aka_title WHERE id = c.movie_id)
)
SELECT 
    movie_title,
    total_cast,
    avg_year,
    latest_year,
    COALESCE(keywords, 'No keywords') AS keywords,
    COALESCE(companies, 'No companies') AS companies
FROM 
    FinalResults
WHERE 
    (avg_year IS NOT NULL AND latest_year >= 2000)
ORDER BY 
    total_cast DESC, latest_year DESC
LIMIT 50;
