WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
TopActors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.person_id) AS num_roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        c.movie_id, a.name
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
    COALESCE(ta.actor_name, 'No Actor') AS actor_name,
    COALESCE(tk.keywords, 'No Keywords') AS keywords,
    COALESCE(ta.num_roles, 0) AS num_roles
FROM 
    TopMovies tm
LEFT JOIN 
    TopActors ta ON tm.movie_id = ta.movie_id
LEFT JOIN 
    MovieKeywords tk ON tm.movie_id = tk.movie_id
ORDER BY 
    tm.production_year DESC, tm.title ASC;
