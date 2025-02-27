WITH RankedMovies AS (
    SELECT 
        m.id as movie_id, 
        m.title, 
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) as rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
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
),
ActorDetails AS (
    SELECT 
        a.id as actor_id, 
        a.name, 
        STRING_AGG(DISTINCT AT.title, ', ') AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title AT ON ci.movie_id = AT.movie_id
    GROUP BY 
        a.id
),
MovieInfo AS (
    SELECT 
        m.id as movie_id,
        'Director: ' || COALESCE((SELECT STRING_AGG(cn.name, ', ') 
                                   FROM movie_companies mc
                                   JOIN company_name cn ON mc.company_id = cn.id
                                   WHERE mc.movie_id = m.id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
                                   GROUP BY mc.movie_id), 'Unknown') as directors,
        COALESCE(mk.keywords, 'No Keywords') as keywords
    FROM 
        aka_title m
    LEFT JOIN 
        MovieKeywords mk ON m.id = mk.movie_id
)
SELECT 
    R.rank,
    M.title,
    M.production_year,
    A.name AS actor_name,
    A.movies AS actor_movies,
    M.directors,
    M.keywords
FROM 
    RankedMovies R
LEFT JOIN 
    ActorDetails A ON A.movies LIKE '%' || R.title || '%'
JOIN 
    MovieInfo M ON R.movie_id = M.movie_id
WHERE 
    R.rank <= 10
ORDER BY 
    R.production_year DESC, R.rank ASC;
