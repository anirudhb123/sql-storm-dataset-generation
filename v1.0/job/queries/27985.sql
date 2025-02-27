WITH RankedMovies AS (
    SELECT 
        T.id AS movie_id,
        T.title,
        T.production_year,
        K.keyword,
        ROW_NUMBER() OVER (PARTITION BY T.id ORDER BY K.keyword) AS keyword_rank
    FROM 
        aka_title T
    JOIN 
        movie_keyword MK ON T.id = MK.movie_id
    JOIN 
        keyword K ON MK.keyword_id = K.id
    WHERE 
        T.production_year BETWEEN 2000 AND 2023
),
FilteredMovies AS (
    SELECT 
        RM.movie_id,
        RM.title,
        RM.production_year,
        STRING_AGG(RM.keyword, ', ') AS keywords
    FROM 
        RankedMovies RM
    WHERE 
        RM.keyword_rank <= 3
    GROUP BY 
        RM.movie_id, RM.title, RM.production_year
),
ActorSummary AS (
    SELECT 
        C.movie_id,
        COUNT(DISTINCT A.person_id) AS actor_count,
        STRING_AGG(DISTINCT A.name, ', ') AS actor_names
    FROM 
        cast_info C
    JOIN 
        aka_name A ON C.person_id = A.person_id
    GROUP BY 
        C.movie_id
)
SELECT 
    FM.title,
    FM.production_year,
    FM.keywords,
    ASUM.actor_count,
    ASUM.actor_names
FROM 
    FilteredMovies FM
LEFT JOIN 
    ActorSummary ASUM ON FM.movie_id = ASUM.movie_id
ORDER BY 
    FM.production_year DESC, 
    ASUM.actor_count DESC;
