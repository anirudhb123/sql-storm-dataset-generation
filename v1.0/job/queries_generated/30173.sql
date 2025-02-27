WITH RECURSIVE ActorMovieCTE AS (
    SELECT 
        c.person_id,
        c.movie_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        movie_rank
    FROM 
        ActorMovieCTE
    WHERE 
        movie_rank <= 5  -- Top 5 films per actor
),
CompanyCTE AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieInfo AS (
    SELECT 
        t.title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        info.info
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        t.id
)
SELECT 
    f.actor_name,
    f.movie_title,
    f.production_year,
    c.company_names,
    m.keywords,
    m.info
FROM 
    FilteredMovies f
LEFT JOIN 
    CompanyCTE c ON f.movie_title = c.movie_title
LEFT JOIN 
    MovieInfo m ON f.movie_title = m.title
ORDER BY 
    f.actor_name,
    f.production_year DESC;
