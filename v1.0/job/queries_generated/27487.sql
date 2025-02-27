WITH MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS companies
    FROM
        aka_title ak
    JOIN
        title m ON ak.movie_id = m.id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name c ON mc.company_id = c.id
    GROUP BY
        m.id, m.title, m.production_year
),

ActorDetails AS (
    SELECT
        p.id AS actor_id,
        ak.name AS actor_name,
        STRING_AGG(m.title, ', ') AS movies
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    JOIN
        title m ON ci.movie_id = m.id
    GROUP BY
        p.id, ak.name
)

SELECT
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.keywords,
    md.companies,
    ad.actor_name,
    ad.movies
FROM
    MovieDetails md
JOIN
    ActorDetails ad ON md.movie_id = ad.actor_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.movie_title
LIMIT 50;

This SQL query does the following:
1. The `MovieDetails` CTE aggregates movie information including alternate names, keywords, and associated companies for movies produced after the year 2000.
2. The `ActorDetails` CTE gathers actor names and the titles of movies they appeared in.
3. The final SELECT query pulls results from both CTEs to provide a comprehensive view, ordering the results by production year and movie title, limiting the output to 50 rows.
