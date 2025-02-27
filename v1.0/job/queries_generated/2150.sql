WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywordCount AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
TopActors AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        ci.movie_id, ak.name
    HAVING 
        COUNT(ci.person_id) > 1
),
MovieCompaniesWithNotes AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        STRING_AGG(mc.note, ', ') AS company_notes
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id, c.name
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    COALESCE(ta.actor_name, 'No actors') AS lead_actor,
    COALESCE(mcwn.company_name, 'No companies') AS production_company,
    COALESCE(mcwn.company_notes, 'No notes') AS production_notes
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywordCount mkc ON mkc.movie_id = rm.title_id
LEFT JOIN 
    TopActors ta ON ta.movie_id = rm.title_id
LEFT JOIN 
    MovieCompaniesWithNotes mcwn ON mcwn.movie_id = rm.title_id
WHERE 
    rm.rn <= 10 -- Limit the results to the top 10 ranked movies per year
ORDER BY 
    rm.production_year DESC, 
    rm.title;
