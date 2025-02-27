WITH movie_details AS (
    SELECT
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        a.name AS actor_name,
        cnt.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY a.name) AS actor_rank
    FROM aka_title mt
    LEFT JOIN cast_info ci ON ci.movie_id = mt.id
    LEFT JOIN aka_name a ON a.person_id = ci.person_id
    LEFT JOIN movie_companies mc ON mc.movie_id = mt.id
    LEFT JOIN company_name cnt ON cnt.id = mc.company_id
    WHERE mt.production_year IS NOT NULL
      AND a.name IS NOT NULL
      AND cnt.name IS NOT NULL
),
actor_analysis AS (
    SELECT
        movie_title,
        production_year,
        kind_id,
        actor_name,
        company_name,
        actor_rank,
        COUNT(*) OVER (PARTITION BY movie_title) AS actor_count
    FROM movie_details
),
modal_actor AS (
    SELECT
        movie_title,
        production_year,
        kind_id,
        actor_name,
        actor_count,
        ROW_NUMBER() OVER (PARTITION BY movie_title ORDER BY actor_count DESC) AS modal_rank
    FROM actor_analysis
),
bizarre_actors AS (
    SELECT
        ma.movie_title,
        ma.production_year,
        ma.actor_name,
        ma.actor_count,
        CASE 
            WHEN ma.actor_count > 2 THEN 'Frequent Actor'
            ELSE 'Rare Actor'
        END AS actor_tiers,
        COALESCE((
            SELECT STRING_AGG(DISTINCT mc.company_name, ', ') 
            FROM movie_companies mc 
            JOIN company_name co ON mc.company_id = co.id 
            WHERE mc.movie_id = ma.movie_id
        ), 'Unknown') AS companies
    FROM modal_actor ma
    WHERE ma.modal_rank = 1
)

SELECT
    ba.movie_title,
    ba.production_year,
    ba.actor_name,
    ba.actor_count,
    ba.actor_tiers,
    ba.companies
FROM bizarre_actors ba
WHERE ba.actor_count > (
    SELECT AVG(actor_count) FROM bizarre_actors
)
ORDER BY ba.production_year DESC, ba.actor_name ASC;

-- Performance Benchmarking Insights
-- This query analyzes the actor participation across movies,
-- their counts and categorizes them into tiers based on frequency.
-- It uses CTEs for modularization, ROW_NUMBER() and COUNT() 
-- window functions for analytics and leverages COALESCE for 
-- handling NULL cases to return a collective view of companies 
-- involved.
