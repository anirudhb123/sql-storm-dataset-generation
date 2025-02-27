WITH RecursiveMovies AS (
    SELECT 
        m.id,
        m.title,
        m.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        COALESCE(cn.name, 'Unknown Company') AS company_name
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id

    UNION ALL 

    SELECT 
        m.id,
        CONCAT(m.title, ' (Part ', rc.season_nr, ')') AS title,
        m.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        COALESCE(cn.name, 'Unknown Company') AS company_name
    FROM aka_title m 
    INNER JOIN complete_cast cc ON m.id = cc.movie_id
    INNER JOIN RecursiveMovies rc ON cc.movie_id = rc.id 
    WHERE m.production_year <= rc.production_year -- ensuring no future movies are included
), 

HighBudgetFilms AS (
    SELECT 
        rm.id, 
        rm.title, 
        rm.production_year, 
        AVG(mi.info) AS average_budget 
    FROM RecursiveMovies rm
    JOIN movie_info mi ON rm.id = mi.movie_id 
    WHERE mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'budget') 
    GROUP BY rm.id, rm.title, rm.production_year
    HAVING AVG(mi.info::numeric) > 100000000 -- films with average budget over 100 million
), 

TitleLength AS (
    SELECT 
        title, 
        LENGTH(title) AS title_length 
    FROM aka_title
)

SELECT 
    hbf.title,
    hbf.production_year,
    hbf.average_budget,
    tl.title_length,
    ROW_NUMBER() OVER (PARTITION BY hbf.production_year ORDER BY hbf.average_budget DESC) AS ranking
FROM HighBudgetFilms hbf
LEFT JOIN TitleLength tl ON hbf.title = tl.title
WHERE tl.title_length IS NOT NULL -- only include titles with length information
  AND EXISTS (SELECT 1 
              FROM movie_info mi 
              WHERE mi.movie_id = hbf.id 
                AND mi.info ILIKE '%special%') -- ensuring the movie has 'special' in info
ORDER BY hbf.production_year DESC, hbf.average_budget DESC;


