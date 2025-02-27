WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS alternative_titles,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        COALESCE(SUM(mc.note), 0) AS total_movie_companies
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
PersonDetails AS (
    SELECT 
        p.id AS person_id,
        ak.name AS aka_name,
        GROUP_CONCAT(DISTINCT c.movie_id ORDER BY c.movie_id) AS movie_ids,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        person_info pi ON ak.person_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'bio')
    GROUP BY 
        ak.name, ak.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.alternative_titles,
    md.keywords,
    pd.person_id,
    pd.aka_name,
    pd.movie_ids,
    pd.movie_count,
    md.total_movie_companies
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
LEFT JOIN 
    PersonDetails pd ON ci.person_id = pd.person_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, pd.movie_count DESC;
