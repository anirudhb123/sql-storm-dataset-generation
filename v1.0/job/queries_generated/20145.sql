WITH RecursiveActorMovies AS (
    SELECT
        ca.person_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY at.production_year DESC) AS rn
    FROM 
        cast_info ca
    JOIN 
        aka_title at ON ca.movie_id = at.id
    WHERE 
        at.production_year IS NOT NULL
),
ReferencedMovies AS (
    SELECT
        rmo.movie_id,
        COUNT(DISTINCT rmo.person_id) AS actor_count,
        SUM(CASE WHEN rmo.production_year < 2000 THEN 1 ELSE 0 END) AS pre_2000_count
    FROM 
        RecursiveActorMovies rmo
    WHERE 
        rmo.rn <= 3  -- limit to top 3 recent films
    GROUP BY 
        rmo.movie_id
),
MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(mk.keyword, 'Unknown') AS keyword,
        m.production_year,
        COALESCE(cd.actor_count, 0) AS actor_count,
        cd.pre_2000_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        ReferencedMovies cd ON m.id = cd.movie_id
)
SELECT
    md.title,
    md.production_year,
    md.keyword,
    md.actor_count,
    md.pre_2000_count,
    (CASE 
        WHEN md.pre_2000_count > 2 THEN 'Classic'
        WHEN md.actor_count = 0 THEN 'No Actors'
        ELSE 'Modern'
    END) AS movie_category,
    (SELECT STRING_AGG(name, ', ')
     FROM aka_name an
     WHERE an.person_id IN (SELECT DISTINCT person_id FROM cast_info ci WHERE ci.movie_id = md.movie_id)
    ) AS actor_names
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 1990 AND 2023
ORDER BY 
    md.production_year DESC,
    md.actor_count DESC
FETCH FIRST 50 ROWS ONLY;
