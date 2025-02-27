WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER(PARTITION BY t.id) AS total_cast_members,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
), 

TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_by_cast <= 5
),

MovieKeywords AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),

FinalOutput AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mk.keyword_list, 'No Keywords') AS keywords,
        COALESCE(comp.name, 'Unknown Company') AS company_name,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = t.id AND mi.info_type_id = 1) AS info_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON mc.movie_id IN (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year)
    LEFT JOIN 
        company_name comp ON mc.company_id = comp.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id IN (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year)
    LEFT JOIN 
        MovieKeywords mk ON mk.movie_id IN (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year)
    GROUP BY 
        tm.title, tm.production_year, mk.keyword_list, comp.name
    HAVING 
        COUNT(DISTINCT ci.person_id) > 0 OR (COUNT(DISTINCT ci.person_id) = 0 AND comp.name IS NULL)
)

SELECT 
    title, 
    production_year, 
    keywords, 
    company_name, 
    total_cast, 
    info_count
FROM 
    FinalOutput
ORDER BY 
    production_year DESC, 
    total_cast DESC;
