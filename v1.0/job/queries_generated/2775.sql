WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title AS t 
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON ci.movie_id = cc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), YearlyTopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies AS rm
    WHERE 
        rm.rank = 1
), MovieDetails AS (
    SELECT 
        yt.title,
        yt.production_year,
        GROUP_CONCAT(DISTINCT c.name) AS company_names,
        STRING_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        YearlyTopMovies AS yt
    LEFT JOIN 
        movie_companies AS mc ON mc.movie_id IN (SELECT m.id FROM aka_title AS m WHERE m.title = yt.title AND m.production_year = yt.production_year)
    LEFT JOIN 
        company_name AS c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword AS mk ON mk.movie_id IN (SELECT m.id FROM aka_title AS m WHERE m.title = yt.title AND m.production_year = yt.production_year)
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        yt.title, yt.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.company_names,
    md.keywords
FROM 
    MovieDetails AS md
WHERE 
    md.production_year IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title;
