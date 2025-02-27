WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        r.role,
        array_agg(a.name ORDER BY a.name) AS actor_names
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, r.role
),

MovieKeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),

FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_names,
        mk.keyword_count
    FROM 
        RankedMovies rm
    JOIN 
        MovieKeywordCount mk ON rm.movie_id = mk.movie_id
    WHERE 
        mk.keyword_count > 3
)

SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.actor_names
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, 
    fm.title ASC;
