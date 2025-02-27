WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        RANK() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_in_year
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.person_id,
        c.movie_id,
        r.role,
        COUNT(c.id) OVER (PARTITION BY c.movie_id) AS total_cast_count,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS casting_order,
        COALESCE(pr.name, 'Unknown') AS person_name
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        aka_name pr ON c.person_id = pr.person_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        string_agg(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_type_id) AS distinct_company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
UniqueKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS unique_keyword_count 
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    cd.person_name,
    cd.role,
    cd.total_cast_count,
    mk.unique_keyword_count,
    mc.companies,
    CAST(CASE 
        WHEN cd.casting_order = 1 THEN 'Lead Actor'
        WHEN cd.casting_order <= 5 THEN 'Supporting Cast'
        ELSE 'Minor Role'
    END AS varchar) AS casting_role,
    COALESCE(cd.role, 'No Role Assigned') AS role_assigned
FROM 
    RankedMovies rm
JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
JOIN 
    UniqueKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE 
    cd.total_cast_count > 0
    AND rm.rank_in_year <= 5
    AND mk.unique_keyword_count IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    rm.title;

This query is designed to provide an elaborate analysis of movies filtered and ranked based on specific criteria. Here's a breakdown of its components:

- **Common Table Expressions (CTEs)**:
  1. **RankedMovies**: Ranks movies by title within the same production year.
  2. **CastDetails**: Extracts casting information, including the total number of cast and determines casting roles based on order.
  3. **MovieCompanies**: Aggregates companies associated with each movie and counts the types of companies.
  4. **UniqueKeywords**: Counts distinct keywords for each movie.

- **Joins**: The main SELECT statement joins the CTEs on `movie_id` to collate detailed information about movies, their casts, the companies involved, and related keywords.

- **Window Functions**: Used to compute ranks, counts, and orders within specific partitions for complex analyses.

- **String Aggregation**: The `string_agg` function is employed to concatenate company names into a single string.

- **CASE Statement**: Assigns casting roles based on the order of a person's appearance in the cast, showcasing the utility of conditional logic in SQL.

- **NULL Handling**: Utilizes `COALESCE` to manage potential NULLs, particularly for missing names or roles.

- **Complicated WHERE Conditions**: Filters based on total casts and ranking, ensuring the output is both relevant and precise.

This query handles various SQL concepts through complex joins, aggregation, and existential logic while ensuring it adheres to the schema provided.
