WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year) AS rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS movie_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role,
        ci.nr_order,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY ci.movie_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
MovieScores AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.actor_name,
        ar.role,
        ar.nr_order,
        COALESCE(SUM(CASE WHEN w.id IS NOT NULL THEN 1 ELSE 0 END), 0) AS award_count,
        MAX(COALESCE(mvi.info, 'No Information')) AS movie_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    LEFT JOIN 
        movie_info mvi ON rm.movie_id = mvi.movie_id AND mvi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword w ON mk.keyword_id = w.id AND w.keyword LIKE '%Award%'
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, ar.actor_name, ar.role, ar.nr_order
),
FinalScores AS (
    SELECT 
        movie_id,
        title,
        production_year,
        MAX(CASE WHEN role IS NOT NULL THEN actor_name END) AS lead_actor,
        COUNT(DISTINCT actor_name) AS total_actors,
        SUM(award_count) AS total_awards,
        STRING_AGG(movie_info, '; ') AS info_summary
    FROM 
        MovieScores
    GROUP BY 
        movie_id, title, production_year
    HAVING 
        COUNT(DISTINCT actor_name) >= 3 AND 
        SUM(award_count) > 0
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.lead_actor,
    f.total_actors,
    f.total_awards,
    COALESCE(f.info_summary, 'No additional information') AS info_summary,
    CASE 
        WHEN f.total_awards > 10 THEN 'Highly Acclaimed'
        WHEN f.total_awards BETWEEN 5 AND 10 THEN 'Moderately Acclaimed'
        ELSE 'Less Acclaimed'
    END AS acclaim_level
FROM 
    FinalScores f
ORDER BY 
    f.total_awards DESC, f.production_year ASC;
