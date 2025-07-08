WITH RECURSIVE TitleCTE AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS title_kind
    FROM 
        aka_title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        t.production_year IS NOT NULL
    UNION ALL
    SELECT 
        tt.id,
        tt.title,
        tt.production_year,
        kt.kind
    FROM 
        aka_title tt
    JOIN 
        kind_type kt ON tt.kind_id = kt.id
    JOIN 
        TitleCTE cte ON tt.episode_of_id = cte.title_id
    WHERE 
        tt.production_year IS NULL
),
ActorInfo AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS note_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL AND c.country_code != 'USA'
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        cte.title AS movie_title,
        cte.production_year,
        cte.title_kind,
        ai.name AS actor_name,
        ai.movie_count,
        ai.note_count,
        mc.company_count
    FROM 
        TitleCTE cte
    LEFT JOIN 
        cast_info ci ON cte.title_id = ci.movie_id
    LEFT JOIN 
        ActorInfo ai ON ci.person_id = ai.person_id
    LEFT JOIN 
        MovieCompanies mc ON cte.title_id = mc.movie_id
    WHERE 
        cte.title_kind = 'movie' AND
        (ai.note_count > 5 OR ai.movie_count > 10)
)
SELECT 
    movie_title,
    production_year,
    title_kind,
    actor_name,
    COALESCE(movie_count, 0) AS total_movies,
    COALESCE(note_count, 0) AS total_notes,
    COALESCE(company_count, 0) AS total_companies
FROM 
    FinalResults
ORDER BY 
    production_year DESC, 
    total_movies DESC NULLS LAST, 
    title_kind;

