WITH RankedTitles AS (
    SELECT 
        title.id AS title_id,
        title.title AS title_name,
        title.production_year,
        RANK() OVER (PARTITION BY title.production_year ORDER BY title.title) AS year_rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        mt.movie_id,
        mt.title,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        aka_title AS mt
    LEFT JOIN 
        movie_companies AS mc ON mt.movie_id = mc.movie_id
    LEFT JOIN 
        company_name AS cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword AS mk ON mt.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS kc ON mk.keyword_id = kc.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.movie_id, mt.title
),
ActorFilms AS (
    SELECT 
        ca.movie_id,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM 
        cast_info AS ca
    JOIN 
        aka_title AS at ON ca.movie_id = at.movie_id
    GROUP BY 
        ca.movie_id
)
SELECT 
    rt.title_name,
    rt.production_year,
    md.company_names,
    md.keyword_count,
    COALESCE(af.actor_count, 0) AS actor_count
FROM 
    RankedTitles AS rt
JOIN 
    MovieDetails AS md ON rt.title_name = md.title
LEFT JOIN 
    ActorFilms AS af ON md.movie_id = af.movie_id
WHERE 
    rt.year_rank <= 10
ORDER BY 
    rt.production_year DESC, rt.title_name ASC;
