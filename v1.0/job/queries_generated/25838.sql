WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        STRING_AGG(keyword, ', ') AS keywords
    FROM 
        RankedMovies
    WHERE 
        keyword_rank <= 3
    GROUP BY 
        movie_id, title, production_year
),
MovieCast AS (
    SELECT 
        mc.movie_id,
        c.name AS actor_name,
        r.role AS role
    FROM 
        complete_cast mc
    JOIN 
        cast_info ci ON mc.subject_id = ci.person_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
MoviesWithCast AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.keywords,
        STRING_AGG(DISTINCT CONCAT(mc.actor_name, ' as ', mc.role), ', ') AS cast
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieCast mc ON tm.movie_id = mc.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, tm.keywords
)
SELECT 
    mwc.title,
    mwc.production_year,
    mwc.keywords,
    mwc.cast
FROM 
    MoviesWithCast mwc
WHERE 
    mwc.cast IS NOT NULL
ORDER BY 
    mwc.production_year DESC, mwc.title;
