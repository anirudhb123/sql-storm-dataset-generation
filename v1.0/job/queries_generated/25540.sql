WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        array_agg(DISTINCT c.role_id) AS role_ids,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
PersonDetails AS (
    SELECT 
        p.id AS person_id,
        a.name AS actor_name,
        a.imdb_index,
        array_agg(DISTINCT ct.kind) AS company_types,
        COUNT(DISTINCT ci.movie_id) AS movies_appeared_in
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        movie_companies mc ON ci.movie_id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        p.id, a.name, a.imdb_index
)
SELECT 
    md.movie_title,
    md.production_year,
    md.movie_keyword,
    pd.actor_name,
    pd.imdb_index,
    pd.company_types,
    pd.movies_appeared_in,
    md.total_cast,
    md.role_ids
FROM 
    MovieDetails md
JOIN 
    cast_info ci ON md.title_id = ci.movie_id
JOIN 
    PersonDetails pd ON ci.person_id = pd.person_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.movie_title;
