WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
HighestRankedMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank = 1
),
CompanyMovieCount AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT co.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    hm.title AS Movie_Title, 
    hm.production_year AS Production_Year, 
    c.company_count AS Company_Count,
    COALESCE(NULLIF(a.name, ''), 'Unknown Actor') AS Lead_Actor,
    COUNT(DISTINCT mk.keyword_id) AS Keyword_Count
FROM 
    HighestRankedMovies hm
LEFT JOIN 
    complete_cast cc ON hm.movie_id = cc.movie_id
LEFT JOIN 
    aka_name a ON cc.subject_id = a.person_id
LEFT JOIN 
    CompanyMovieCount c ON hm.movie_id = c.movie_id
LEFT JOIN 
    movie_keyword mk ON hm.movie_id = mk.movie_id
WHERE 
    hm.production_year > 2000 
    AND c.company_count > 2
GROUP BY 
    hm.title, hm.production_year, c.company_count, a.name
ORDER BY 
    Production_Year DESC, Company_Count DESC;
