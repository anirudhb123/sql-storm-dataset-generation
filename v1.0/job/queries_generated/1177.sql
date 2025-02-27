WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        c.person_id, a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT ki.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        m.movie_id
),
CombinedData AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ta.actor_name,
        ta.movie_count,
        mi.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        TopActors ta ON ta.movie_count > 5
    LEFT JOIN 
        MovieInfo mi ON rm.movie_id = mi.movie_id
)
SELECT 
    cd.movie_id,
    cd.title,
    cd.production_year,
    cd.actor_name,
    COALESCE(cd.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN cd.production_year < 2000 THEN 'Classic'
        WHEN cd.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    CombinedData cd
WHERE 
    cd.year_rank <= 10
ORDER BY 
    cd.production_year DESC, 
    cd.movie_id;
