WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS actor_count
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast d ON a.id = d.movie_id
    LEFT JOIN 
        cast_info c ON d.subject_id = c.id
    WHERE 
        a.production_year IS NOT NULL
), ActorInfo AS (
    SELECT 
        ak.person_id,
        ak.name,
        ak.surname_pcode,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY ak.name) AS name_rank
    FROM 
        aka_name ak 
    WHERE 
        ak.surname_pcode IS NOT NULL
), MovieKeywords AS (
    SELECT 
        m.title,
        k.keyword
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
), CombinedResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        ai.name AS actor_name,
        ai.surname_pcode,
        mk.keyword AS movie_keyword,
        rm.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorInfo ai ON rm.actor_count > 0 
                       AND ai.name_rank <= rm.actor_count
    LEFT JOIN 
        MovieKeywords mk ON rm.title = mk.title
)
SELECT 
    cr.title,
    cr.production_year,
    cr.actor_name,
    cr.surname_pcode,
    STRING_AGG(DISTINCT cr.movie_keyword, ', ') AS keywords,
    COUNT(*) FILTER (WHERE cr.actor_name IS NOT NULL) AS total_actors,
    COALESCE(MIN(cr.production_year), 'N/A') AS earliest_year
FROM 
    CombinedResults cr
GROUP BY 
    cr.title, cr.production_year, cr.actor_name, cr.surname_pcode
HAVING 
    COUNT(*) FILTER (WHERE cr.actor_name IS NOT NULL) > 2
ORDER BY 
    cr.production_year DESC, cr.title;
