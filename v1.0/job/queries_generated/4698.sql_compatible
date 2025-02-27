
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(cc.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(cc.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cp.kind, 'Unknown') AS company_type,
        COALESCE(ak.name, 'Unknown') AS actor_name,
        rm.cast_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_type cp ON mc.company_type_id = cp.id
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        rm.rank <= 3 
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_type,
    STRING_AGG(DISTINCT md.actor_name, ', ') AS actors,
    md.cast_count
FROM 
    MovieDetails md
GROUP BY 
    md.movie_id, md.title, md.production_year, md.company_type, md.cast_count
HAVING 
    md.cast_count > 0
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
