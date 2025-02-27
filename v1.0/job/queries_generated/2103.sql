WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
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
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalMovieStats AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(ac.actor_count, 0) AS total_actors,
        COALESCE(mk.keywords, 'None') AS keywords,
        mcb.company_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.id = ac.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.id = mk.movie_id
    LEFT JOIN 
        MovieCompanies mcb ON rm.id = mcb.movie_id
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    f.title,
    f.production_year,
    f.total_actors,
    f.keywords,
    CASE 
        WHEN f.total_actors IS NULL OR f.total_actors = 0 THEN 'No Actors Listed'
        ELSE 'Actors Available'
    END AS actor_status,
    LEFT(f.keywords, LENGTH(f.keywords) - 1) AS trimmed_keywords
FROM 
    FinalMovieStats f
WHERE 
    f.production_year >= 2000
ORDER BY 
    f.production_year DESC, 
    f.total_actors DESC;
