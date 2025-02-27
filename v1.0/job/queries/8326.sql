WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        mii.info AS budget,
        mii.note AS budget_note,
        STRING_AGG(DISTINCT CONCAT(ak.name, ' (', rt.role, ')'), ', ') AS actors
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info_idx mii ON mii.movie_id = rm.movie_id AND mii.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
    LEFT JOIN 
        cast_info ci ON ci.movie_id = rm.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        role_type rt ON rt.id = ci.role_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.actor_count, mii.info, mii.note
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_count,
    COALESCE(md.budget, 'N/A') AS budget,
    COALESCE(md.budget_note, 'No notes') AS budget_note,
    COALESCE(md.actors, 'No actors listed') AS actors
FROM 
    MovieDetails md
ORDER BY 
    md.actor_count DESC, 
    md.production_year DESC
LIMIT 10;
