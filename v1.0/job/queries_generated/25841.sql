WITH MovieDetails AS (
    SELECT 
        T.title AS movie_title,
        T.production_year,
        C.name AS company_name,
        R.role AS cast_role,
        A.name AS actor_name,
        CT.kind AS company_type,
        MK.keyword AS movie_keyword
    FROM 
        aka_title T
    JOIN 
        movie_companies MC ON T.id = MC.movie_id
    JOIN 
        company_name C ON MC.company_id = C.id
    JOIN 
        company_type CT ON MC.company_type_id = CT.id
    JOIN 
        complete_cast CC ON T.id = CC.movie_id
    JOIN 
        cast_info CI ON CC.subject_id = CI.id
    JOIN 
        role_type R ON CI.role_id = R.id
    JOIN 
        aka_name A ON CI.person_id = A.person_id
    LEFT JOIN 
        movie_keyword MK ON T.id = MK.movie_id
    WHERE 
        T.production_year >= 2000
),

AggregatedData AS (
    SELECT 
        movie_title,
        COUNT(DISTINCT actor_name) AS actor_count,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        MIN(production_year) AS earliest_year,
        MAX(production_year) AS latest_year,
        COUNT(DISTINCT company_name) AS company_count,
        STRING_AGG(DISTINCT company_type, ', ') AS company_types
    FROM 
        MovieDetails
    GROUP BY 
        movie_title
)

SELECT 
    movie_title,
    actor_count,
    keywords,
    earliest_year,
    latest_year,
    company_count,
    company_types
FROM 
    AggregatedData
ORDER BY 
    actor_count DESC,
    movie_title;

This SQL query achieves various objectives for benchmarking string processing:

1. **Common Table Expressions (CTE)**: It utilizes two CTEs (`MovieDetails` and `AggregatedData`) for enhanced readability and organization of the query.
  
2. **Joins**: It performs multiple joins across various tables to gather comprehensive movie and cast information.

3. **Filtering**: It focuses on movies produced after the year 2000.

4. **Aggregation**: It uses aggregation functions (`COUNT`, `STRING_AGG`, `MIN`, `MAX`) to summarize the necessary data.

5. **Ordering**: Finally, it orders the resulting dataset by the number of distinct actors, providing a meaningful output for further analysis or reporting.
