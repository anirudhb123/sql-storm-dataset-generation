WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        SUM(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS info_present_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON tm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    LEFT JOIN 
        movie_info mi ON tm.title = (SELECT title FROM aka_title WHERE id = mi.movie_id)
    GROUP BY 
        tm.title, 
        tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.actors,
    md.companies,
    md.keyword_count,
    md.info_present_count
FROM 
    MovieDetails md
JOIN 
    title t ON md.title = t.title
WHERE 
    md.keyword_count > 2 
ORDER BY 
    md.production_year DESC,
    md.actors DESC NULLS LAST;
