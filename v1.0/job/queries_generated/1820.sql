WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_within_year
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS actors,
        string_agg(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.title = (SELECT at.title FROM aka_title at WHERE at.id = ci.movie_id)
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = ci.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.actors,
    md.keywords,
    COALESCE(SUM(mci.company_id), 0) AS production_companies_count
FROM 
    MovieDetails md
LEFT JOIN 
    movie_companies mci ON md.title = (SELECT at.title FROM aka_title at WHERE at.id = mci.movie_id)
GROUP BY 
    md.title, md.production_year, md.actors, md.keywords
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
