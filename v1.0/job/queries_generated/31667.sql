WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id, ci.movie_id, 1 AS depth
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    WHERE an.name ILIKE '%Smith%'  -- filtering for actors with a specific name

    UNION ALL

    SELECT ci.person_id, ci.movie_id, ah.depth + 1
    FROM cast_info ci
    JOIN ActorHierarchy ah ON ci.movie_id = ah.movie_id
    WHERE ci.person_id != ah.person_id  -- prevent self-referencing
),

MovieDetails AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT an.name) AS actors,
        AVG(mi.info::float) AS average_rating -- Assuming 'info' holds a numeric string for ratings
    FROM aka_title mt
    JOIN cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN aka_name an ON ci.person_id = an.person_id
    LEFT JOIN movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY mt.id
),

MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),

FinalResults AS (
    SELECT 
        md.title,
        md.production_year,
        md.actor_count,
        md.actors,
        mc.company_name,
        mc.company_type,
        COALESCE(md.average_rating, 0) AS average_rating
    FROM MovieDetails md
    LEFT JOIN MovieCompanyInfo mc ON md.movie_id = mc.movie_id
    WHERE md.actor_count > 1 -- only movies with more than 1 actor
)

SELECT 
    fr.title,
    fr.production_year,
    fr.actor_count,
    fr.actors,
    fr.company_name,
    fr.company_type,
    fr.average_rating,
    RANK() OVER (PARTITION BY fr.company_type ORDER BY fr.average_rating DESC) as rating_rank
FROM FinalResults fr
WHERE 
    fr.average_rating IS NOT NULL
    AND fr.company_type IS NOT NULL
ORDER BY fr.average_rating DESC;

### Explanation:
- The query utilizes **CTEs (Common Table Expressions)** for organizing the data effectively.
- The **recursive CTE** `ActorHierarchy` generates a hierarchy of actors who have worked in the same movie.
- The `MovieDetails` CTE gathers various details about movies, including actor counts and average ratings.
- The `MovieCompanyInfo` CTE joins movie companies to their respective movies.
- In the `FinalResults` CTE, we combine the previous results to format our final output.
- The final selection includes both the company type and rating for each movie, with a **window function** to provide a ranking based on average ratings per company type.
- Filters are applied to ensure a more concise dataset (e.g., only movies with more than one actor and non-null values for average ratings).
