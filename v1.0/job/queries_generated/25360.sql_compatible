
WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT k.keyword, ',' ORDER BY k.keyword) AS keywords,
        STRING_AGG(DISTINCT c.name, ',' ORDER BY c.name) AS companies
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies AS mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name AS c ON mc.company_id = c.id
    GROUP BY 
        m.id, m.title, m.production_year
),
ActorDetails AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS num_movies
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    JOIN 
        person_info AS pi ON a.person_id = pi.person_id
    JOIN 
        name AS n ON pi.person_id = n.imdb_id
    WHERE 
        n.gender = 'F' 
    GROUP BY 
        a.person_id, a.name
),
MovieStatistics AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.keywords,
        md.companies,
        ad.actor_name,
        ad.num_movies
    FROM 
        MovieDetails md
    JOIN 
        ActorDetails ad ON ad.person_id IN (
            SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = md.movie_id
        )
)
SELECT 
    ms.movie_id,
    ms.movie_title,
    ms.production_year,
    ms.keywords,
    ms.companies,
    ms.actor_name,
    ms.num_movies
FROM 
    MovieStatistics ms
ORDER BY 
    ms.production_year DESC, 
    ms.movie_title;
