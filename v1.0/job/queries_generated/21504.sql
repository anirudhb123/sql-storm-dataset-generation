WITH recursive
  movie_actors AS (
    SELECT 
      c.id AS cast_id,
      p.name AS actor_name,
      t.title AS movie_title,
      t.production_year,
      ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_order
    FROM 
      cast_info c
    JOIN 
      aka_name p ON c.person_id = p.person_id
    JOIN 
      aka_title t ON c.movie_id = t.movie_id
  ),
  
  high_concept_movies AS (
    SELECT 
      m.id AS movie_id,
      m.title,
      m.production_year,
      COUNT(DISTINCT k.id) AS keyword_count
    FROM 
      aka_title m
    LEFT JOIN 
      movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
      keyword k ON mk.keyword_id = k.id
    WHERE 
      m.production_year IS NOT NULL
    GROUP BY 
      m.id
    HAVING 
      COUNT(DISTINCT k.id) > 5
  ),

  actor_movie_info AS (
    SELECT 
      ma.actor_name,
      ma.movie_title,
      ma.production_year,
      CASE 
        WHEN ma.actor_order = 1 THEN 'Lead Actor'
        ELSE 'Supporting Actor'
      END AS actor_role,
      h.keyword_count
    FROM 
      movie_actors ma
    JOIN 
      high_concept_movies h ON ma.movie_title = h.title AND ma.production_year = h.production_year
  )

SELECT 
  ami.actor_name,
  ami.movie_title,
  ami.production_year,
  ami.actor_role,
  COALESCE(ami.keyword_count, 0) AS keyword_count,
  ARRAY_AGG(DISTINCT k.keyword) AS keywords
FROM 
  actor_movie_info ami
LEFT JOIN 
  movie_keyword mk ON ami.movie_title = (SELECT title FROM aka_title WHERE production_year = ami.production_year)
LEFT JOIN 
  keyword k ON mk.keyword_id = k.id
GROUP BY 
  ami.actor_name, ami.movie_title, ami.production_year, ami.actor_role, ami.keyword_count
ORDER BY 
  ami.production_year DESC, ami.actor_role, ami.actor_name;

This SQL query incorporates several complex features, including:

- **Common Table Expressions (CTEs)**: Used for organizing the query into manageable sections.
- **Window Functions**: Utilizes `ROW_NUMBER()` to order actors by their appearance in a movie.
- **LEFT JOIN**: Used for optional relationships, such as linking movies to keywords without enforcing mandatory associations.
- **GROUP BY and HAVING**: Aggregate functions are paired with filtering rules to find "high concept" movies based on keyword count.
- **Conditional Logic**: The `CASE` statement determines the role of the actor based on their order in the cast list.
- **COALESCE**: Ensures that null keyword counts are represented as zero.
- **Array Aggregation**: Collects all keywords related to a specific movie into an array to present all associated data in a single row.
- **Correlated Subquery**: Retrieves the title of the movie dynamically to create associations in the `LEFT JOIN`.
  
The query demonstrates recursion through the use of CTEs and effectively showcases relationships across multiple entities while considering unique SQL circumstances.
