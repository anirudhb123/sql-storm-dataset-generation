
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        RM.movie_id,
        RM.title,
        RM.production_year
    FROM 
        RankedMovies RM
    WHERE 
        RM.title_rank <= 5
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        TM.movie_id,
        TM.title,
        TM.production_year,
        COALESCE(AC.actor_count, 0) AS actor_count
    FROM 
        TopMovies TM
    LEFT JOIN 
        ActorCount AC ON TM.movie_id = AC.movie_id
),
MovieKeywords AS (
    SELECT 
        MK.movie_id,
        STRING_AGG(K.keyword, ', ' ORDER BY K.keyword) AS keywords
    FROM 
        movie_keyword MK
    JOIN 
        keyword K ON MK.keyword_id = K.id
    GROUP BY 
        MK.movie_id
),
FinalReport AS (
    SELECT 
        MD.movie_id,
        MD.title,
        MD.production_year,
        MD.actor_count,
        COALESCE(MK.keywords, 'No Keywords') AS keywords
    FROM 
        MovieDetails MD
    LEFT JOIN 
        MovieKeywords MK ON MD.movie_id = MK.movie_id
)
SELECT 
    FR.title,
    FR.production_year,
    CASE 
        WHEN FR.actor_count > 0 THEN 'Has Actors'
        ELSE 'No Actors'
    END AS actor_status,
    FR.keywords,
    CASE 
        WHEN FR.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(FR.production_year AS VARCHAR)
    END AS production_year_str
FROM 
    FinalReport FR
WHERE 
    (FR.title ILIKE '%adventure%' OR FR.keywords ILIKE '%adventure%')
    AND (FR.actor_count IS NOT NULL OR FR.actor_count = 0)
ORDER BY 
    FR.production_year DESC, 
    FR.title;
