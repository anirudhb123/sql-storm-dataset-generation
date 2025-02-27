WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL 
        AND mt.kind_id IS NOT NULL
    UNION ALL
    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.kind_id ORDER BY mh.production_year DESC) AS rank,
        ROW_NUMBER() OVER (PARTITION BY mh.kind_id ORDER BY mh.title) AS title_order
    FROM
        MovieHierarchy mh
),
ConsolidatedResults AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank,
        ct.kind AS company_type,
        COUNT(mc.company_id) AS company_count,
        SUM(CASE WHEN ki.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count
    FROM
        RankedMovies rm
    LEFT JOIN movie_companies mc ON mc.movie_id = rm.movie_id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = rm.movie_id
    LEFT JOIN keyword ki ON mk.keyword_id = ki.id
    GROUP BY
        rm.movie_id, rm.title, rm.production_year, rm.rank, ct.kind
)
SELECT
    cr.movie_id,
    cr.title,
    cr.production_year,
    cr.rank,
    cr.company_type,
    cr.company_count,
    cr.keyword_count,
    (CASE
        WHEN cr.company_count > 10 THEN 'Highly Sponsored'
        WHEN cr.company_count BETWEEN 5 AND 10 THEN 'Moderately Sponsored'
        ELSE 'Sparsely Sponsored'
    END) AS sponsorship_level
FROM
    ConsolidatedResults cr
WHERE
    cr.rank = 1
    AND cr.production_year BETWEEN 1990 AND 2020
    AND (cr.company_type IS NULL OR cr.company_type NOT LIKE 'Distributor%')
ORDER BY
    cr.production_year DESC,
    cr.title ASC;

### Explanation:
- **CTEs (Common Table Expressions)**: 
  - `MovieHierarchy` recursively builds a hierarchy of movies based on their links, using a depth tracking mechanism.
  - `RankedMovies` applies ranking and ordering to the movies based on their kind and production year.
  
- **Joins**:
  - Several LEFT JOINs are used to link movie data with companies and keywords, allowing counting and filtering based on those relationships.

- **Window Functions**:
  - `RANK()` and `ROW_NUMBER()` provide insights into movie standings and ordering without needing to apply a global sort.

- **Complicated Logic**:
  - The `CASE` statement categorizes movies based on the number of associated companies.

- **NULL Logic**:
  - The query checks for NULL company types or excludes specific types of companies, showcasing complex filtering capabilities.

- **Final Output**:
  - Provides a sorted list of top-ranking movies from a defined range, considering strange relations such as the sponsorship level based on company involvement.

