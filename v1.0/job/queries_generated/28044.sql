WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        rc.role,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rc ON ci.role_id = rc.id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_name
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 3 -- Get the top 3 actors for each movie
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    ORDER BY 
        keyword_count DESC
    LIMIT 10
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_name,
    pk.keyword
FROM 
    FilteredMovies fm
JOIN 
    PopularKeywords pk ON fm.title = (SELECT title FROM title WHERE id = pk.movie_id LIMIT 1)
ORDER BY 
    fm.production_year DESC, fm.actor_name;
