
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        mc.movie_id,
        a.name AS actor_name,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info mc
    JOIN 
        aka_name a ON mc.person_id = a.person_id
    JOIN 
        role_type rt ON mc.role_id = rt.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    (SELECT COUNT(*) FROM MovieCast WHERE movie_id = rm.movie_id) AS actor_count,
    (
        SELECT LISTAGG(mca.actor_name, ', ')
        FROM MovieCast mca
        WHERE mca.movie_id = rm.movie_id
    ) AS actors,
    CASE 
        WHEN COUNT(*) > 0 AND MAX(mc.actor_rank) <= 5 
        THEN 'Top 5 Actors Present' 
        ELSE 'No Top 5 Actors' 
    END AS actor_presence
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, mk.keywords
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
