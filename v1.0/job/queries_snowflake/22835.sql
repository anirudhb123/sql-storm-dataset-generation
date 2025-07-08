
WITH RecursiveTopMovies AS (
    SELECT 
        mt.title, 
        mt.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_in_year
    FROM 
        aka_title mt
    JOIN 
        cast_info c ON mt.id = c.movie_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.title, mt.production_year
), 
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT cn.id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
), 
KeywordMovieCounts AS (
    SELECT 
        mk.movie_id, 
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rtm.title,
    rtm.production_year,
    rtm.total_cast,
    COALESCE(cmc.total_companies, 0) AS total_companies,
    COALESCE(kmc.keywords_list, 'No Keywords') AS keywords,
    CASE 
        WHEN rtm.total_cast > 15 THEN 'Big Cast'
        WHEN rtm.total_cast BETWEEN 5 AND 15 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    RecursiveTopMovies rtm
LEFT JOIN 
    CompanyMovieCounts cmc ON rtm.title = (SELECT title FROM aka_title WHERE id = cmc.movie_id LIMIT 1)
LEFT JOIN 
    KeywordMovieCounts kmc ON rtm.title = (SELECT mt.title FROM aka_title mt WHERE mt.id = kmc.movie_id LIMIT 1)
WHERE 
    rtm.rank_in_year <= 10
ORDER BY 
    rtm.production_year DESC, rtm.total_cast DESC;
