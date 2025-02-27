WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id 
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_count,
        md.actor_names,
        md.keywords,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.actor_count DESC) AS rank_by_actors
    FROM 
        MovieDetails md
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        rm.actor_names,
        rm.keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_actors <= 5
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.actor_count,
    COALESCE(fm.actor_names, 'No actors available') AS actor_names,
    COALESCE(ARRAY_TO_STRING(fm.keywords, ', '), 'No keywords') AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_info mi ON fm.movie_id = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis') 
    AND mi.info IS NOT NULL
ORDER BY 
    fm.production_year DESC, fm.actor_count DESC;
