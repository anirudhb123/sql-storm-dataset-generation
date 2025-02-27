WITH RECURSIVE CompanyHierarchy AS (
    -- Base case: Select all companies
    SELECT id, name, country_code, 1 AS level
    FROM company_name
    WHERE country_code IS NOT NULL

    UNION ALL

    -- Recursive case: Build relationships based on the movie companies they are associated with
    SELECT cn.id, cn.name, cn.country_code, ch.level + 1
    FROM company_name cn
    JOIN movie_companies mc ON cn.id = mc.company_id
    JOIN CompanyHierarchy ch ON mc.movie_id IN (
        SELECT movie_id FROM movie_companies WHERE company_id = ch.id
    )
    WHERE cn.country_code IS NOT NULL
),
-- Another CTE to fetch movie details along with actor info aggregating from various tables
MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        MAX(mci.note) AS movie_notes,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mci ON t.id = mci.movie_id AND mci.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
    GROUP BY 
        t.id
),
-- Now to find interesting movies that are either highly rated (based on some notes implying ratings) or have a certain actor in their cast
InterestingMovies AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_count,
        md.actors,
        md.movie_notes,
        (
            SELECT COUNT(*)
            FROM complete_cast cc
            WHERE cc.movie_id = md.movie_id AND cc.status_id NOT IN (3) -- Excluding certain statuses
        ) AS complete_cast_count
    FROM 
        MovieDetails md
    WHERE 
        md.actor_count > 3 
        OR md.movie_notes ILIKE '%blockbuster%' -- Matching certain keyword phrases
)
SELECT 
    ch.name AS company_name,
    im.title AS movie_title,
    im.production_year,
    im.actor_count,
    im.actors,
    im.movie_notes,
    im.complete_cast_count,
    CASE 
        WHEN im.actor_count > 5 THEN 'Highly Active'
        ELSE 'Moderate Activity'
    END AS activity_level
FROM 
    InterestingMovies im
JOIN 
    movie_companies mc ON im.movie_id = mc.movie_id
JOIN 
    company_name ch ON mc.company_id = ch.id
WHERE 
    ch.country_code IN ('USA', 'GB')  -- Filter for specific countries
    AND im.complete_cast_count > 0
ORDER BY 
    im.actor_count DESC, 
    im.production_year DESC
LIMIT 50;
