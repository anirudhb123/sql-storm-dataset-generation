
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
),
ActorNames AS (
    SELECT 
        a.person_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        an.actor_names,
        COALESCE(mc.company_count, 0) AS company_count,
        COALESCE(mc.company_names, 'No Companies') AS company_names,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        CASE 
            WHEN COALESCE(kc.keyword_count, 0) > 5 THEN 'Popular'
            WHEN COALESCE(kc.keyword_count, 0) = 0 THEN 'No Keywords'
            ELSE 'Moderately Known'
        END AS keyword_popularity
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorNames an ON rm.movie_id = (
            SELECT movie_id FROM cast_info WHERE person_id IN (
                SELECT person_id FROM aka_name WHERE name LIKE '%Smith%'
            ) LIMIT 1
        )
    LEFT JOIN 
        MovieCompanies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        KeywordCount kc ON rm.movie_id = kc.movie_id
    WHERE 
        rm.rn <= 5
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_names,
    md.company_count,
    md.company_names,
    md.keyword_count,
    md.keyword_popularity
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.movie_id
LIMIT 10;
