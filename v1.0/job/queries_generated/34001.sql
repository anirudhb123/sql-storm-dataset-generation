WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastMemberRanks AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rank
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    GROUP BY mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cr.rank, 0) AS actor_rank,
    ci.company_count,
    ci.companies
FROM MovieHierarchy mh
LEFT JOIN CastMemberRanks cr ON mh.movie_id = cr.movie_id AND cr.rank <= 5
LEFT JOIN CompanyInfo ci ON mh.movie_id = ci.movie_id
WHERE mh.level = 1
ORDER BY mh.production_year DESC, mh.title;

This SQL query involves:

1. **Recursive CTE (`MovieHierarchy`)**: This recursively fetches movies from the `aka_title` table starting from the year 2000, building a hierarchy of linked movies.

2. **Window Functions (`ROW_NUMBER()`)**: In the `CastMemberRanks` CTE, it assigns a rank to cast members for each movie.

3. **Aggregation and String Functions**: The `CompanyInfo` CTE aggregates company names and counts distinct companies per movie in `movie_companies`.

4. **Outer Joins**: The main query performs left joins to retrieve the actor ranks and company information, allowing for null values if no data exists.

5. **Complicated Predicates**: The use of `COALESCE` for handling nulls in the actor ranks allows for flexibility in the output.

6. **Final Selection**: The main query selects relevant columns, ordering the results by production year and title for easier readability.
