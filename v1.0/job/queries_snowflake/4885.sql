
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.cast_count
    FROM 
        RankedMovies rm 
    WHERE 
        rm.rank_within_year <= 5
),
ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    LISTAGG(ad.actor_name, ', ') WITHIN GROUP (ORDER BY ad.actor_name) AS actors
FROM 
    FilteredMovies fm
LEFT JOIN 
    ActorDetails ad ON fm.movie_id = ad.movie_id
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, fm.cast_count
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
