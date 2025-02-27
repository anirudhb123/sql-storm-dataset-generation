WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        GROUP_CONCAT(DISTINCT an.name) AS actor_names,
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
        COUNT(DISTINCT subject_id) AS avg_actors_per_movie
    FROM 
        complete_cast 
    GROUP BY 
        movie_id
),
IndustryTrends AS (
    SELECT 
        excel.production_year,
        AVG(avg_actors_per_movie) AS avg_with_actor,
        COUNT(DISTINCT md.company_id) AS total_companies
    FROM 
        MovieDetails md 
    JOIN 
        AverageActors excel ON md.movie_id = excel.movie_id 
    GROUP BY 
        md.production_year
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    actor_names,
    company_count,
    keywords,
    movie_type,
    COALESCE(IndustryTrends.avg_with_actor, 0) AS avg_actors,
    COALESCE(IndustryTrends.total_companies, 0) AS total_industry_companies
FROM 
    MovieDetails
LEFT JOIN 
    IndustryTrends ON MovieDetails.production_year = IndustryTrends.production_year
ORDER BY 
    production_year DESC, movie_title;
