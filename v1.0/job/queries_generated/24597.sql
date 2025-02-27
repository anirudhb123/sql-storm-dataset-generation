WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),

ActorsWithNotes AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movies_appeared,
        MAX(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
),

MoviesByCompany AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT c.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),

FinalBenchmark AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        ac.movies_appeared,
        ac.has_note,
        mb.company_count,
        CASE 
            WHEN ac.movies_appeared > 5 THEN 'Featured Actor'
            WHEN ac.has_note = 1 THEN 'Noteworthy'
            ELSE 'Regular'
        END AS actor_status
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorsWithNotes ac ON ac.movies_appeared > 0
    LEFT JOIN 
        MoviesByCompany mb ON mb.movie_id = rm.movie_id
    WHERE 
        rm.rank <= 10 
        AND (mb.company_count IS NULL OR mb.company_count > 2)
)

SELECT 
    *,
    COALESCE(actor_status, 'No Actor') AS final_actor_status,
    CONCAT(title, ' (', production_year, ')') AS full_movie_title
FROM 
    FinalBenchmark
WHERE 
    CAST(CAST(cast_count AS TEXT) AS INTEGER) > 1
ORDER BY 
    production_year DESC, title;
