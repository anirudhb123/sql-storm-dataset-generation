WITH RecursiveMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mci.note, 'No Company Note') AS company_note,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name mci ON mc.company_id = mci.id
    WHERE 
        t.production_year IS NOT NULL
),
RankedPeople AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(ci.movie_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(ci.movie_id) DESC, ak.name) AS rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
),
ComplexMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.company_note,
        rp.name AS actor_name,
        rp.movie_count,
        CASE 
            WHEN rp.movie_count > 5 THEN 'Prolific Actor'
            WHEN rp.movie_count IS NULL THEN 'Unknown Actor'
            ELSE 'Regular Actor'
        END AS actor_status
    FROM 
        RecursiveMovies rm
    LEFT JOIN 
        RankedPeople rp ON rm.movie_id = rp.person_id
),
ConsolidatedResults AS (
    SELECT 
        *,
        LEAD(actor_name, 1) OVER (PARTITION BY movie_id ORDER BY actor_status DESC) AS next_actor,
        LAG(actor_name, 1) OVER (PARTITION BY movie_id ORDER BY actor_status) AS previous_actor
    FROM 
        ComplexMovieInfo
)
SELECT 
    DISTINCT movie_id,
    title,
    company_note,
    actor_name,
    actor_status,
    next_actor,
    previous_actor
FROM 
    ConsolidatedResults
WHERE 
    (next_actor IS NULL OR previous_actor IS NULL OR actor_status = 'Prolific Actor')
ORDER BY 
    movie_id, actor_status DESC;
