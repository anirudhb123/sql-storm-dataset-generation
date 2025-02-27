WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        ak.name AS actor_name,
        pi.info AS actor_info
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = 1 
    WHERE 
        t.production_year > 2000
),
AggregateStats AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT actor_name) AS actor_count,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        MAX(production_year) AS latest_year
    FROM 
        MovieDetails
    GROUP BY 
        movie_id
)
SELECT 
    md.title,
    md.production_year,
    asv.actor_count,
    asv.keywords,
    asv.latest_year
FROM 
    MovieDetails md
JOIN 
    AggregateStats asv ON md.movie_id = asv.movie_id
ORDER BY 
    asv.actor_count DESC, 
    md.production_year ASC;
