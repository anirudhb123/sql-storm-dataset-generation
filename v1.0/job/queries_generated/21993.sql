WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_type_id) AS unique_company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        title m ON mc.movie_id = m.id
    GROUP BY 
        m.movie_id
),
NullCheck AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(c.actor_count, 0) AS actor_count,
        COALESCE(cd.company_names, 'No Companies') AS company_names,
        COALESCE(cd.unique_company_types, 0) AS unique_company_types,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY c.actor_count DESC) AS rank_in_year
    FROM 
        title m
    LEFT JOIN 
        ActorCounts c ON m.id = c.movie_id
    LEFT JOIN 
        CompanyDetails cd ON m.id = cd.movie_id
    LEFT JOIN 
        RankedTitles t ON m.id = t.title_id
    WHERE 
        m.production_year IS NOT NULL
)
SELECT 
    n.name AS actor_name,
    nt.title AS movie_title,
    nm.production_year,
    cc.actor_count,
    NULLIF(cc.unique_company_types, 0) AS unique_company_types,
    CASE 
        WHEN cc.unique_company_types IS NULL THEN 'No Companies' 
        ELSE cc.company_names 
    END AS company_names
FROM 
    name n
JOIN 
    cast_info ci ON n.id = ci.person_id
JOIN 
    title nt ON ci.movie_id = nt.id
JOIN 
    NullCheck cc ON nt.id = cc.movie_id
WHERE 
    n.name ILIKE '%a%'  -- Filter for actors with 'a' in their name
    AND nt.production_year BETWEEN 2000 AND 2020  -- Narrowing down to a specific age of cinema
    AND (cc.actor_count > 2 OR cc.unique_company_types > 1)  -- Movies with significant involvement
ORDER BY 
    nc.unique_company_types DESC,
    cc.actor_count DESC,
    nm.production_year DESC;

### Explanation of SQL Query Components
- **Common Table Expressions (CTEs)**: Used for organizing complex queries and breaking down the problem into manageable parts (e.g., `RankedTitles`, `ActorCounts`, `CompanyDetails`, `NullCheck`).
- **Window Functions**: Utilize `ROW_NUMBER()` to rank titles by production year and actors count within the same year.
- **NULL Logic**: Utilizes `COALESCE` to handle and display NULL values in a user-friendly manner, particularly for companies.
- **LEFT JOINs**: Used to ensure that all titles are included even if they have no associated actors or companies.
- **CASE Statements**: Provides customized behavior based on the conditions (NULL checks).
- **String Aggregation**: `STRING_AGG` to concatenate company names for each movie.
- **Unusual Predicate Uses**: Filtering on conditions ensuring a mix of actors and companies.
- **ORDER BY Clause**: A multi-layered sort that prioritizes company types, actor counts, and years of production.
