WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
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
        rn <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.title = ci.title
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        tm.title, tm.production_year
),
ActorStats AS (
    SELECT 
        an.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_note_count
    FROM 
        aka_name an
    JOIN 
        cast_info ci ON an.person_id = ci.person_id
    GROUP BY 
        an.name
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_names,
    als.name AS actor_name,
    als.movie_count,
    als.null_note_count,
    ks.keyword_count
FROM 
    MovieDetails md
JOIN 
    ActorStats als ON md.actor_names LIKE '%' || als.name || '%'
LEFT JOIN 
    KeywordStats ks ON md.title = (SELECT title FROM aka_title WHERE movie_id = ks.movie_id LIMIT 1)
ORDER BY 
    md.production_year DESC, als.movie_count DESC;
