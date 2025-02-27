WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),

HighProfileActors AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT title) AS title_count
    FROM 
        RankedTitles
    WHERE 
        year_rank <= 5
    GROUP BY 
        actor_name
    HAVING 
        COUNT(DISTINCT title) > 3
),

MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mp.name, 'No Company') AS production_company,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_name mp ON mc.company_id = mp.id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    GROUP BY 
        m.id, mp.name
),

ActorProductionCount AS (
    SELECT 
        ra.actor_name,
        COUNT(DISTINCT md.movie_id) AS movie_count,
        SUM(md.keyword_count) AS total_keywords
    FROM 
        HighProfileActors ha
    JOIN 
        RankedTitles ra ON ha.actor_name = ra.actor_name
    JOIN 
        MovieDetails md ON ra.title = md.title
    GROUP BY 
        ra.actor_name
)

SELECT 
    apc.actor_name,
    apc.movie_count,
    apc.total_keywords,
    CASE 
        WHEN apc.total_keywords > 10 THEN 'Keyword Enthusiast'
        WHEN apc.total_keywords BETWEEN 5 AND 10 THEN 'Keyword Engaged'
        ELSE 'Keyword Minimalist' 
    END AS keyword_engagement
FROM 
    ActorProductionCount apc
WHERE 
    apc.movie_count > 3
ORDER BY 
    apc.total_keywords DESC
LIMIT 10;

This SQL query performs the following operations:
1. **Common Table Expressions (CTEs)**: It uses CTEs to rank titles for actors, count high-profile actors based on their titles, and summarize movie details by production company while counting associated keywords.
2. **Window Functions**: The `RANK()` function is used to assign ranks to actors based on the production year, which is crucial for determining influential actors within recent years.
3. **Null Logic**: The use of `COALESCE` ensures that if a movie has no associated production company, it is labeled as 'No Company'.
4. **Correlated Subqueries**: The joining of relevant rows across CTEs correlates actors, their movies, and associated keywords.
5. **Use of Complex Predicates**: The `HAVING` clause filters actors with significant production volume, while the main query categorizes actors into engagement levels contingent on their keyword usage.
6. **Bizarre SQL Semantics**: The naming conventions and outrageous label selections like 'Keyword Enthusiast' and 'Keyword Minimalist' offer a quirky touch that infers engagement in an unusual context.

The result of this query provides a tailored list of high-profile actors, the count of their productions, evident keyword interaction, and a subjective engagement classification—all of which are insightful for performance benchmarking in a movie database context.
