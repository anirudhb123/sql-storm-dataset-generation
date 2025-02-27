WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.kind AS company_type,
        COALESCE(SUM(mi.info::int), 0) AS total_ratings,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY SUM(mi.info::int) DESC) as rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    GROUP BY 
        a.id, a.title, a.production_year, c.kind
), 
FilteredMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.company_type,
        rm.total_ratings
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 3
        AND rm.production_year IS NOT NULL
), 
ActorStats AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        AVG(ci.nr_order) AS avg_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(ci.movie_id) > 10
), 
MovieActorAssociation AS (
    SELECT 
        fm.movie_title,
        fm.production_year,
        ARRAY_AGG(DISTINCT as.actor_name) AS actor_names
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        cast_info ci ON fm.movie_title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    LEFT JOIN 
        aka_name as ON ci.person_id = as.person_id
    GROUP BY 
        fm.movie_title, fm.production_year
)
SELECT 
    ma.movie_title,
    ma.production_year,
    ma.actor_names,
    CASE 
        WHEN ma.production_year < 2000 THEN 'Classic'
        WHEN ma.production_year BETWEEN 2000 AND 2015 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era,
    CASE 
        WHEN ma.actor_names IS NOT NULL THEN 'Includes Actors'
        ELSE 'No Actors'
    END AS actor_presence
FROM 
    MovieActorAssociation ma
ORDER BY 
    ma.production_year DESC,
    ma.movie_title;
