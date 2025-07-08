
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieGenres AS (
    SELECT 
        mk.movie_id,
        LISTAGG(kt.keyword, ', ') WITHIN GROUP (ORDER BY kt.keyword) AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        COALESCE(mg.genres, '') AS genres,
        COALESCE(info.movie_info, 'Information not available') AS additional_info
    FROM 
        aka_title m
    LEFT JOIN 
        ActorCounts ac ON m.id = ac.movie_id
    LEFT JOIN 
        MovieGenres mg ON m.id = mg.movie_id
    LEFT JOIN (
        SELECT 
            movie_id, 
            LISTAGG(info, '; ') WITHIN GROUP (ORDER BY info) AS movie_info
        FROM 
            movie_info 
        GROUP BY 
            movie_id
    ) AS info ON m.id = info.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    md.genres,
    md.additional_info
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
    AND md.actor_count >= (SELECT AVG(actor_count) FROM ActorCounts) 
    OR EXISTS (
        SELECT 1
        FROM RankedMovies rm
        WHERE rm.title = md.title AND rm.rank_by_year <= 5
    )
ORDER BY 
    md.production_year DESC,
    md.title ASC
LIMIT 10;
