
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS actor_count,
        DENSE_RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS production_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        production_rank <= 5
),
MoviesWithKeywords AS (
    SELECT 
        tm.title,
        tm.production_year,
        mwk.keyword AS movie_keyword
    FROM 
        TopMovies tm 
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
    LEFT JOIN 
        keyword mwk ON mwk.id = mk.keyword_id
),
FinalResults AS (
    SELECT 
        mw.title,
        mw.production_year,
        LISTAGG(mw.movie_keyword, ', ') WITHIN GROUP (ORDER BY mw.movie_keyword) AS keywords
    FROM 
        MoviesWithKeywords mw
    GROUP BY 
        mw.title, mw.production_year
)
SELECT 
    fr.title,
    fr.production_year,
    COALESCE(fr.keywords, 'No keywords') AS keywords_info
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, 
    fr.title;
