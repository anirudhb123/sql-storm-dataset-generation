WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_cast_order
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorRankings AS (
    SELECT 
        ka.person_id,
        ka.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rank
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    GROUP BY 
        ka.person_id, ka.name
),
KeywordUsage AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_count,
    md.companies,
    md.avg_cast_order,
    ar.name AS top_actor,
    ar.movie_count,
    ku.keywords
FROM 
    MovieDetails md
LEFT JOIN 
    ActorRankings ar ON ar.rank = 1
LEFT JOIN 
    KeywordUsage ku ON md.movie_id = ku.movie_id
WHERE 
    md.company_count > 2
ORDER BY 
    md.production_year DESC, md.title ASC
LIMIT 10;
