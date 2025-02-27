WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_per_year
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorRoleCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT ci.role_id) FILTER (WHERE ci.role_id IS NOT NULL) AS distinct_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TitleRatings AS (
    SELECT 
        t.id AS title_id,
        COALESCE(mi.info, 'Not Rated') AS rating
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
)
SELECT 
    rm.movie_title,
    rm.production_year,
    arc.actor_count,
    arc.distinct_roles,
    mk.keywords_list,
    tr.rating
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoleCounts arc ON rm.movie_id = arc.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    TitleRatings tr ON rm.movie_id = tr.title_id
WHERE 
    rank_per_year <= 10 
    AND (arc.actor_count IS NULL OR arc.actor_count > 5)
    AND (tr.rating IS NOT NULL AND tr.rating != 'Not Rated')
ORDER BY 
    rm.production_year DESC, 
    arc.distinct_roles DESC NULLS LAST;