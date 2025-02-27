WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT ca.person_id) AS total_actors,
        AVG(CASE WHEN ca.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY a.id) AS avg_actor_notes,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, COUNT(DISTINCT ca.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ca ON a.id = ca.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
GroupedKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS combined_keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MoviesWithDetails AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.total_actors,
        rm.avg_actor_notes,
        gk.combined_keywords,
        CASE WHEN rm.total_actors = 0 THEN NULL ELSE rm.avg_actor_notes END AS avg_notes_nonzero
    FROM 
        RankedMovies rm
    LEFT JOIN 
        GroupedKeywords gk ON rm.movie_title = (SELECT title FROM aka_title WHERE id = gk.movie_id)
    WHERE 
        rm.year_rank <= 5 OR (rm.total_actors > (SELECT AVG(total_actors) FROM RankedMovies))
)
SELECT 
    mwd.movie_title,
    mwd.production_year,
    COALESCE(mwd.combined_keywords, 'No keywords') AS keywords,
    COALESCE(mwd.total_actors, 0) AS actor_count,
    CASE 
        WHEN mwd.avg_actor_notes IS NULL THEN 'No data'
        WHEN mwd.avg_notes_nonzero IS NULL THEN 'No actors'
        ELSE 'Data available'
    END AS notes_status
FROM 
    MoviesWithDetails mwd
ORDER BY 
    mwd.production_year DESC, 
    mwd.actor_count DESC
LIMIT 10;
