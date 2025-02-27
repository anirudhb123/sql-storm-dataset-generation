WITH RECURSIVE TopMovies AS (
    SELECT at.id, at.title, at.production_year, COUNT(c.id) AS cast_count
    FROM aka_title at
    LEFT JOIN cast_info c ON at.movie_id = c.movie_id
    WHERE at.kind_id = 1  -- Only consider movies
    GROUP BY at.id, at.title, at.production_year
    HAVING COUNT(c.id) > 0
    
    UNION ALL
    
    SELECT at.id, at.title, at.production_year, COUNT(c.id) AS cast_count
    FROM aka_title at
    JOIN TopMovies tm ON tm.id = at.id
    LEFT JOIN cast_info c ON at.movie_id = c.movie_id
    GROUP BY at.id, at.title, at.production_year
    HAVING COUNT(c.id) > 0
),
MovieKeywords AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
CompanyTitles AS (
    SELECT mc.movie_id, STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE mc.note IS NULL  -- Only companies with no notes
    GROUP BY mc.movie_id
),
MovieInfo AS (
    SELECT m.id AS movie_id, 
           m.title AS title, 
           COALESCE(k.keywords, 'No keywords') AS keywords,
           COALESCE(c.companies, 'No companies') AS companies,
           m.production_year,
           COUNT(DISTINCT ci.person_id) AS total_cast
    FROM aka_title m
    LEFT JOIN MovieKeywords k ON m.id = k.movie_id
    LEFT JOIN CompanyTitles c ON m.id = c.movie_id
    LEFT JOIN cast_info ci ON m.movie_id = ci.movie_id
    GROUP BY m.id, k.keywords, c.companies, m.title, m.production_year
),
RankedMovies AS (
    SELECT *,
           RANK() OVER (PARTITION BY production_year ORDER BY total_cast DESC) AS ranking
    FROM MovieInfo
)

SELECT movie_id, title, production_year, keywords, companies, total_cast, ranking
FROM RankedMovies
WHERE ranking <= 5  -- Retrieve top 5 movies per year
ORDER BY production_year, ranking;
