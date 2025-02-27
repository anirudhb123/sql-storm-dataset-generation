WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
),
ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        RankedTitles rt ON ci.movie_id = rt.title_id
    GROUP BY 
        ci.person_id
),
TopActors AS (
    SELECT 
        am.person_id
    FROM 
        ActorMovieCounts am
    WHERE 
        am.movie_count > 5
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(STRING_AGG(DISTINCT c.name, ', '), 'Unknown') AS actors,
        COUNT(DISTINCT kw.keyword) FILTER (WHERE kw.keyword IS NOT NULL) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword kw ON t.id = kw.movie_id
    WHERE 
        EXISTS (SELECT 1 FROM TopActors ta WHERE ta.person_id = ci.person_id)
    GROUP BY 
        t.id
)
SELECT 
    md.title,
    md.production_year,
    md.actors,
    md.keyword_count
FROM 
    MovieDetails md
WHERE 
    md.production_year = (SELECT MAX(production_year) FROM MovieDetails) 
    OR md.keyword_count > 3
ORDER BY 
    md.production_year DESC, 
    md.title;
