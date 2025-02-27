WITH MovieTitleCounts AS (
    SELECT 
        a.title AS movie_title,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.movie_id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.id
    LEFT JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    GROUP BY 
        a.title
),
Top10Movies AS (
    SELECT 
        movie_title,
        actor_count,
        keyword_count,
        RANK() OVER (ORDER BY actor_count DESC, keyword_count DESC) AS rank
    FROM 
        MovieTitleCounts
)
SELECT 
    tn.movie_title,
    tk.actor_count,
    tk.keyword_count,
    c.name AS company_name,
    t.kind AS movie_type
FROM 
    Top10Movies tk
JOIN 
    aka_title ta ON tk.movie_title = ta.title
JOIN 
    movie_companies mc ON ta.movie_id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type t ON mc.company_type_id = t.id
WHERE 
    tk.rank <= 10
ORDER BY 
    tk.actor_count DESC, tk.keyword_count DESC;

This SQL query performs the following actions:

1. It creates a Common Table Expression (CTE) called `MovieTitleCounts` that aggregates titles from the `aka_title` table, counting distinct actors and keywords associated with each movie.
   
2. A second CTE named `Top10Movies` retrieves the top 10 movies based on the number of actors and keywords, using a ranking system to rank them accordingly.

3. Finally, it selects from the `Top10Movies` CTE and joins with other tables to fetch related company names and movie types for those top-ranked movies. The final result is ordered by actor count and keyword count.
