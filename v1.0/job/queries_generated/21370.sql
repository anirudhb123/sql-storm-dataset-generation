WITH Recursive RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'Feature Film')
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        c.movie_id,
        COUNT(*) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id, c.movie_id
),
TopActors AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT a.movie_id) AS total_movies
    FROM 
        ActorMovieCounts a
    JOIN 
        aka_name n ON a.person_id = n.person_id
    WHERE 
        n.name IS NOT NULL
    GROUP BY 
        a.person_id
    HAVING 
        COUNT(DISTINCT a.movie_id) > 10
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TopMoviesWithActors AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        COALESCE(STRING_AGG(DISTINCT n.name, ', '), 'No Actors') AS actor_names,
        COALESCE(mk.keyword_list, 'No Keywords') AS keywords
    FROM 
        RankedMovies r
    LEFT JOIN 
        cast_info c ON r.movie_id = c.movie_id
    LEFT JOIN 
        aka_name n ON c.person_id = n.person_id
    LEFT JOIN 
        MovieKeywords mk ON r.movie_id = mk.movie_id
    GROUP BY 
        r.movie_id, r.title, r.production_year
    HAVING 
        r.title_rank <= 5
    ORDER BY 
        r.production_year DESC, r.title
)
SELECT 
    t.movie_id,
    t.title,
    t.production_year,
    t.actor_names,
    t.keywords
FROM 
    TopMoviesWithActors t
WHERE 
    EXISTS (
        SELECT 1 
        FROM TopActors ta 
        WHERE ta.person_id IN (SELECT n.person_id FROM aka_name n WHERE n.name LIKE '%Smith%')
    ) 
    AND NOT EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = t.movie_id 
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Banned')
    )
ORDER BY 
    t.production_year, t.title;
