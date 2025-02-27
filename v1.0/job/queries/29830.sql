
WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases,
        COUNT(DISTINCT mci.company_id) AS production_companies
    FROM 
        title t
    LEFT JOIN 
        aka_title ak_title ON t.id = ak_title.movie_id
    LEFT JOIN 
        aka_name ak ON ak.id = ak_title.id
    LEFT JOIN 
        movie_companies mci ON t.id = mci.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT n.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        name n ON c.person_id = n.imdb_id
    GROUP BY 
        c.movie_id
),
GenreDetails AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    md.title_id,
    md.title,
    md.production_year,
    md.aliases,
    COALESCE(ad.actor_count, 0) AS actor_count,
    COALESCE(ad.actor_names, '') AS actor_names,
    COALESCE(gd.genres, '') AS genres,
    (md.production_companies + COALESCE(ad.actor_count, 0)) AS estimated_budget
FROM 
    MovieDetails md
LEFT JOIN 
    ActorDetails ad ON md.title_id = ad.movie_id
LEFT JOIN 
    GenreDetails gd ON md.title_id = gd.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title;
