WITH MovieDetails AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON at.movie_id = mc.movie_id
    GROUP BY 
        at.id, at.title, at.production_year, k.keyword
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_exist
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
),
TopActors AS (
    SELECT 
        actor_name,
        movie_count,
        notes_exist,
        RANK() OVER (ORDER BY movie_count DESC, notes_exist DESC) AS actor_rank
    FROM 
        ActorDetails
    WHERE 
        movie_count > 0
)

SELECT 
    md.title,
    md.production_year,
    md.keyword,
    md.company_count,
    COALESCE(ta.actor_name, 'Unknown Actor') AS actor_name,
    ta.movie_count AS actor_movie_count,
    ta.notes_exist AS actor_notes_exist
FROM 
    MovieDetails md
LEFT JOIN 
    TopActors ta ON md.year_rank = ta.actor_rank
WHERE 
    md.production_year IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.keyword ASC, 
    actor_movie_count DESC NULLS LAST
LIMIT 100;
