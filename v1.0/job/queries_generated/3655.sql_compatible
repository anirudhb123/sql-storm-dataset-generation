
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorInfo AS (
    SELECT 
        a.name,
        a.person_id,
        COUNT(DISTINCT m.id) AS movies_played,
        AVG(COALESCE(m.production_year, 0)) AS avg_years
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.id
    GROUP BY 
        a.name, a.person_id
    HAVING 
        COUNT(DISTINCT m.id) > 5
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    ai.name AS actor_name,
    ai.movies_played,
    ai.avg_years,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    ActorInfo ai ON ai.person_id IN (
        SELECT 
            ci.person_id 
        FROM 
            cast_info ci 
        WHERE 
            ci.movie_id = tm.movie_id
    )
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
WHERE 
    tm.cast_count > 2
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
