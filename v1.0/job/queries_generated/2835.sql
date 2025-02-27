WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS actor_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorInfo AS (
    SELECT 
        a.name AS actor_name,
        r.role,
        t.title,
        t.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    JOIN 
        role_type r ON ci.role_id = r.id
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
FinalResults AS (
    SELECT 
        rm.title AS movie_title,
        rm.production_year,
        ai.actor_name,
        ai.role,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorInfo ai ON rm.title = ai.title AND rm.production_year = ai.production_year
    LEFT JOIN 
        MovieKeywords mk ON rm.id = mk.movie_id
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    movie_title,
    production_year,
    STRING_AGG(DISTINCT actor_name || ' as ' || role, ', ') AS cast,
    keywords
FROM 
    FinalResults
GROUP BY 
    movie_title, production_year, keywords
ORDER BY 
    production_year DESC, movie_title;
