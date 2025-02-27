WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mkw.keyword_id) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mkw ON t.id = mkw.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), MovieCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        GROUP_CONCAT(DISTINCT ak.name) AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.company_count,
        mc.cast_count,
        mc.actor_names,
        rm.keyword_count,
        ROW_NUMBER() OVER (ORDER BY rm.production_year DESC, rm.company_count DESC, rm.keyword_count DESC) AS rank
    FROM 
        RankedMovies rm
    JOIN 
        MovieCast mc ON rm.movie_id = mc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.company_count,
    md.cast_count,
    md.actor_names,
    md.keyword_count
FROM 
    MovieDetails md
WHERE 
    md.rank <= 20
ORDER BY 
    md.production_year DESC, md.company_count DESC, md.keyword_count DESC;
