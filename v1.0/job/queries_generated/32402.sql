WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rank
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    JOIN 
        title t ON cc.movie_id = t.id
    GROUP BY 
        ci.person_id
),
TopActors AS (
    SELECT 
        ah.person_id,
        ah.movie_count
    FROM 
        ActorHierarchy ah
    WHERE 
        ah.rank <= 10
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    a.name,
    a.id AS actor_id,
    md.title,
    md.production_year,
    md.company_count,
    md.company_names,
    RANK() OVER (PARTITION BY md.production_year ORDER BY md.company_count DESC) AS rank_within_year
FROM 
    aka_name a
JOIN 
    TopActors ta ON a.person_id = ta.person_id
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    MovieDetails md ON cc.movie_id = md.title
ORDER BY 
    ta.movie_count DESC, md.production_year DESC;

### Explanation:
1. **Common Table Expression (CTE)**:
   - `ActorHierarchy`: Calculates the number of movies each actor has been involved in using a combination of joins. It also ranks the actors based on their movie count.
   - `TopActors`: Filters out the top 10 actors who have the highest movie involvement.
   - `MovieDetails`: Gathers the movie titles, production years, a count of associated companies, and their names.

2. **Final Selection**:
   - This pulls together names from the `aka_name` table with the previously defined CTEs to provide a ranked listing of actors, their involvement in movies, and details about those movies including company participation.

3. **Window Function**: 
   - Utilized to rank movies within each production year based on the number of companies involved.

4. **String Aggregation**: 
   - Collects the names of companies involved in each movie into a single string.

5. **Outer Joins**: 
   - Incorporation of LEFT JOIN ensures that movies with no associated companies are still returned.

This complex query is designed to assess performance through multiple joins, aggregations, and a recursive structure.
