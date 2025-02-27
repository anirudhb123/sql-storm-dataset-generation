WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COALESCE(AVG(mi.info::numeric), 0) AS average_review_score
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Review Score')
    GROUP BY 
        t.id
),

ActorDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
)

SELECT 
    md.title,
    md.production_year,
    md.companies,
    md.keywords,
    md.average_review_score,
    ad.actor_count,
    ad.actor_names
FROM 
    MovieDetails md
LEFT JOIN 
    ActorDetails ad ON md.movie_id = ad.movie_id
WHERE 
    md.production_year >= 2000 
ORDER BY 
    md.production_year DESC, 
    md.average_review_score DESC;
