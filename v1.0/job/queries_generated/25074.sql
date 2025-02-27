WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        COALESCE(STRING_AGG(DISTINCT cn.name, ', '), 'No Companies') AS companies
    FROM 
        title t
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.id
),
ActorDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        GROUP_CONCAT(DISTINCT n.name ORDER BY n.name) AS actors
    FROM 
        cast_info c
    JOIN 
        name n ON c.person_id = n.id
    GROUP BY 
        c.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.keywords,
    ad.actor_count,
    ad.actors,
    CASE 
        WHEN md.production_year IS NOT NULL THEN 
            CASE 
                WHEN md.production_year < 2000 THEN 'Classic'
                WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
                ELSE 'Recent'
            END
        ELSE 'Unknown Year'
    END AS era,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = md.movie_id) AS info_count
FROM 
    MovieDetails md
LEFT JOIN 
    ActorDetails ad ON md.movie_id = ad.movie_id
ORDER BY 
    md.production_year DESC, ad.actor_count DESC;
