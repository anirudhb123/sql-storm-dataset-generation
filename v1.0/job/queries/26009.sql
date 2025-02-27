
WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        t.kind AS movie_type
    FROM 
        aka_title mt 
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id 
    JOIN 
        aka_name an ON cc.subject_id = an.id 
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id 
    JOIN 
        movie_keyword mw ON mt.id = mw.movie_id 
    JOIN 
        keyword kw ON mw.keyword_id = kw.id 
    JOIN 
        kind_type t ON mt.kind_id = t.id 
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023 
    GROUP BY 
        mt.id, mt.title, mt.production_year, t.kind
),
AverageActors AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT subject_id) AS avg_actors_per_movie
    FROM 
        complete_cast 
    GROUP BY 
        movie_id
),
IndustryTrends AS (
    SELECT 
        md.production_year,
        AVG(excel.avg_actors_per_movie) AS avg_with_actor,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        MovieDetails md 
    JOIN 
        AverageActors excel ON md.movie_id = excel.movie_id 
    JOIN 
        movie_companies mc ON md.movie_id = mc.movie_id
    GROUP BY 
        md.production_year
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.actor_names,
    md.company_count,
    md.keywords,
    md.movie_type,
    COALESCE(it.avg_with_actor, 0) AS avg_actors,
    COALESCE(it.total_companies, 0) AS total_industry_companies
FROM 
    MovieDetails md
LEFT JOIN 
    IndustryTrends it ON md.production_year = it.production_year
ORDER BY 
    md.production_year DESC, md.movie_title;
