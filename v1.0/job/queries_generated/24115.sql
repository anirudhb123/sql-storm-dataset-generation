WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularTitles AS (
    SELECT 
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_cast <= 5
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT m.id) AS movie_count
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id, co.name, ct.kind
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    pt.title,
    pt.production_year,
    cd.company_name,
    cd.company_type,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN cd.movie_count > 1 THEN 'Multiple'
        ELSE 'Single'
    END AS company_count_type,
    (SELECT COUNT(*) 
     FROM cast_info ci 
     WHERE ci.movie_id IN (SELECT movie_id FROM movie_companies WHERE company_id IN (SELECT id FROM company_name WHERE name = cd.company_name))) AS associated_cast_count
FROM 
    PopularTitles pt
LEFT JOIN 
    CompanyDetails cd ON cd.movie_id IN (SELECT id FROM aka_title WHERE title = pt.title AND production_year = pt.production_year)
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = cd.movie_id
WHERE 
    cd.company_name IS NOT NULL OR cd.company_type IS NOT NULL
ORDER BY 
    pt.production_year DESC, pt.title;

In this elaborate SQL query:

- **Common Table Expressions (CTEs)** are used to break down the query into manageable parts:
  - `RankedMovies`: Computes rank by the number of cast members per production year.
  - `PopularTitles`: Pulls the top 5 movies per year based on the rank of cast size.
  - `CompanyDetails`: Summarizes movie companies and their types per movie.
  - `MovieKeywords`: Aggregates keywords associated with movies.

- **LEFT JOINs** are used to ensure that movies with no associated companies or keywords are still included.

- **COALESCE** handles NULL values for keywords.

- A **correlated subquery** counts the total associated cast for movies linked to a specific company.

- There are **string aggregation functions** and CASE expressions to denote how many companies are associated with each movie.

- This query combines complex predicates, CTEs, aggregation, and outer joins, making it suitable for performance benchmarking.
