WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_count_rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(NULLIF(ki.kind, ''), 'Unknown') AS genre,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(l.link_type_id) AS avg_link_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        kind_type ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        movie_link l ON rm.movie_id = l.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, ki.kind
),
TopMovies AS (
    SELECT 
        *,
        CASE 
            WHEN actor_count_rank <= 5 THEN 'Top Tier'
            ELSE 'Standard'
        END AS movie_tier
    FROM 
        RankedMovies
    WHERE 
        actor_count_rank <= 10
)
SELECT 
    md.title,
    md.production_year,
    md.genre,
    md.company_count,
    md.avg_link_type,
    tm.movie_tier
FROM 
    MovieDetails md
JOIN 
    TopMovies tm ON md.movie_id = tm.movie_id
WHERE 
    md.company_count > 0
ORDER BY 
    md.production_year DESC, 
    md.company_count DESC
LIMIT 10;
