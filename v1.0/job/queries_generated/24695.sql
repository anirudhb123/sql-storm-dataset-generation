WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        RK.Rank,
        COALESCE(mci.company_count, 0) AS company_count
    FROM (
        SELECT
            title,
            production_year,
            ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(DISTINCT cast.movie_id) DESC) AS Rank
        FROM
            aka_title t
        LEFT JOIN cast_info cast ON t.id = cast.movie_id
        GROUP BY 
            t.title, t.production_year
    ) AS RK

    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(DISTINCT company_id) AS company_count
        FROM 
            movie_companies
        GROUP BY 
            movie_id
    ) AS mci ON RK.movie_id = mci.movie_id
    WHERE 
        RK.Rank <= 5  -- Top 5 movies per production year
),

ActorDetails AS (
    SELECT
        a.name,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY c.nr_order) AS role_order
    FROM
        aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    WHERE
        NULLIF(a.name, '') IS NOT NULL  -- Filter out empty names
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),

FinalResult AS (
    SELECT 
        rm.title,
        rm.production_year,
        ad.name AS actor_name,
        ad.role_order,
        mk.keywords,
        CASE 
            WHEN rm.company_count > 0 THEN 'Produced'
            ELSE 'Not Produced'
        END AS company_status
    FROM 
        RankedMovies rm
    LEFT JOIN ActorDetails ad ON rm.movie_id = ad.movie_id
    LEFT JOIN MovieKeywords mk ON rm.movie_id = mk.movie_id
)

SELECT 
    title,
    production_year,
    actor_name,
    role_order,
    keywords,
    company_status
FROM 
    FinalResult
WHERE 
    actor_name IS NOT NULL
ORDER BY 
    production_year DESC, role_order ASC;

This SQL query does the following:

1. Defines a Common Table Expression (CTE) `RankedMovies` that ranks movies by the number of cast members within each production year.
2. Creates another CTE `ActorDetails` that lists actors with their respective movies, while filtering out empty names.
3. A third CTE `MovieKeywords` aggregates keywords associated with each movie into a single string.
4. Combines these results in the `FinalResult` CTE, which includes company production status based on the count of associated companies.
5. The final selection from `FinalResult` ensures only actors with a valid name are included, ordered by production year and role order.

This query incorporates various SQL features such as CTEs, window functions, outer joins, string aggregation, and NULL handling logic, all while addressing corner cases and ensuring clarity and rigor in its operations.
