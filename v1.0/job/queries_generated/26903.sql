WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year
    FROM 
        aka_title t
),
TopActors AS (
    SELECT 
        ca.movie_id,
        a.name AS actor_name,
        COUNT(ca.person_role_id) AS role_count
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    GROUP BY 
        ca.movie_id, a.name
),
HighRoleCounts AS (
    SELECT 
        movie_id,
        actor_name
    FROM 
        TopActors
    WHERE 
        role_count > 2
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mk.keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    ha.actor_name,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
FROM 
    MovieDetails md
JOIN 
    HighRoleCounts ha ON md.movie_id = ha.movie_id
GROUP BY 
    md.title, md.production_year, ha.actor_name
ORDER BY 
    md.production_year DESC, 
    md.title;
