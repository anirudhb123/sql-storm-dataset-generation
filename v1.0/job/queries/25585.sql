
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000 
        AND c.country_code = 'USA'
    GROUP BY 
        t.id, t.title, t.production_year, c.name
),
RichMovieDetails AS (
    SELECT
        md.*,
        (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = md.movie_id) AS info_count,
        (SELECT COUNT(DISTINCT ci.note) FROM cast_info ci WHERE ci.movie_id = md.movie_id) AS unique_roles_count
    FROM 
        MovieDetails md
)
SELECT 
    movie_id,
    title,
    production_year,
    company_name,
    keywords,
    actor_names,
    info_count,
    unique_roles_count
FROM 
    RichMovieDetails
ORDER BY 
    production_year DESC,
    title;
