WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.kind AS company_type,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        aka_title ak ON ak.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ca ON ca.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COALESCE(MAX(pi.info), 'No Info') AS info
    FROM 
        aka_name a
    LEFT JOIN 
        person_info pi ON a.person_id = pi.person_id
    GROUP BY 
        a.id, a.name
)

SELECT
    md.title,
    md.production_year,
    md.company_type,
    md.aka_names,
    md.keywords,
    md.cast_count,
    ad.name AS actor_name,
    ad.info AS actor_info
FROM 
    MovieDetails md
LEFT JOIN 
    complete_cast cc ON md.movie_id = cc.movie_id
LEFT JOIN 
    ActorDetails ad ON cc.subject_id = ad.actor_id
ORDER BY 
    md.production_year DESC, md.title;
