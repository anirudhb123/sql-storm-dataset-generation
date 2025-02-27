WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT ki.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    WHERE 
        t.production_year IS NOT NULL AND t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT 
        ai.person_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes_percentage
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        MovieDetails md ON ci.movie_id = md.movie_id
    GROUP BY 
        ai.person_id, ak.name
),
RankedActors AS (
    SELECT 
        person_id,
        name,
        movie_count,
        has_notes_percentage,
        RANK() OVER (ORDER BY movie_count DESC, has_notes_percentage DESC) AS rank
    FROM 
        ActorDetails
)
SELECT 
    ra.name,
    ra.movie_count,
    ra.has_notes_percentage,
    md.title,
    md.production_year,
    md.companies,
    md.keyword_count
FROM 
    RankedActors ra
JOIN 
    MovieDetails md ON ra.movie_count > 0
WHERE 
    ra.rank <= 10
ORDER BY 
    ra.movie_count DESC;
