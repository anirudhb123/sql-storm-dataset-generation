WITH MovieKeywords AS (
    SELECT
        mt.id AS movie_title_id,
        mt.title,
        GROUP_CONCAT(mk.keyword) AS keywords
    FROM
        aka_title mt
    JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY
        mt.id, mt.title
),

ActorDetails AS (
    SELECT
        ak.id AS aka_id,
        ak.name AS actor_name,
        ak.person_id,
        GROUP_CONCAT(DISTINCT ci.movie_id) AS movie_ids,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY
        ak.id, ak.name, ak.person_id
),

CompanyInfo AS (
    SELECT
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
)

SELECT
    mt.movie_title_id,
    mt.title,
    ak.actor_name,
    ak.movie_count,
    mk.keywords,
    ci.companies,
    ci.company_types
FROM
    MovieKeywords mt
JOIN
    ActorDetails ak ON ak.movie_ids LIKE '%' || mt.movie_title_id || '%'
JOIN
    CompanyInfo ci ON ci.movie_id = mt.movie_title_id
WHERE
    mt.keywords LIKE '%thriller%'
ORDER BY
    ak.movie_count DESC, mt.title;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `MovieKeywords`: Retrieves the titles and concatenated keywords of movies identified by the `aka_title` and `movie_keyword` tables.
   - `ActorDetails`: Gathers information on actors including their name, associated movie IDs, and the count of movies they acted in from `aka_name` and `cast_info`.
   - `CompanyInfo`: Collects company names and types related to each movie from `movie_companies`, `company_name`, and `company_type`.

2. **Final Selection**: 
   - Combines the CTEs to extract a list of movies, their titles, associated actors and movies count, keywords, and production companies that include those defined as thrillers.

3. **Ordering**: 
   - The result is ordered first by the number of movies an actor has played in (descending) and then by the movie title.

This elaborate query benchmarks string processing capabilities through multiple joins and aggregations, employing string functions like `GROUP_CONCAT` and `LIKE` for keyword filtering.
