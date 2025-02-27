WITH RECURSIVE MovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info c ON c.movie_id = cc.movie_id
    WHERE 
        t.production_year IS NOT NULL -- Exclude movies without production year
    GROUP BY 
        t.id
    UNION ALL
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.actor_count
    FROM 
        MovieCTE m
    JOIN 
        movie_link ml ON ml.movie_id = m.movie_id
    JOIN 
        aka_title t ON t.id = ml.linked_movie_id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.actor_count
    FROM 
        MovieCTE m
    WHERE 
        m.actor_count > 5 AND m.production_year >= 2000
),
MovieKeywords AS (
    SELECT 
        fm.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        FilteredMovies fm
    JOIN 
        movie_keyword mk ON mk.movie_id = fm.movie_id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        fm.movie_id
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = fm.movie_id) AS complete_cast_count,
    (SELECT COUNT(DISTINCT p.person_id) 
     FROM person_info p 
     WHERE p.info_type_id = 1 
     AND p.person_id IN (SELECT DISTINCT c.person_id FROM cast_info c WHERE c.movie_id = fm.movie_id)) AS notable_actors
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = fm.movie_id
ORDER BY 
    fm.production_year DESC, fm.actor_count DESC;
