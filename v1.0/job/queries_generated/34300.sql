WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        aka_title at ON m.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
),
RankedCast AS (
    SELECT 
        ci.movie_id,
        ak.name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rank_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
SelectedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(rc.name, 'Unknown') AS lead_actor,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        RANK() OVER (ORDER BY mh.production_year DESC) AS year_rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        RankedCast rc ON mh.movie_id = rc.movie_id AND rc.rank_order = 1
    LEFT JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    WHERE 
        mh.production_year > 2000
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, rc.name
)
SELECT 
    sm.title,
    sm.production_year,
    sm.lead_actor,
    sm.production_companies,
    CASE 
        WHEN sm.year_rank <= 10 THEN 'Top Recent Movies'
        ELSE 'Other Movies'
    END AS category
FROM 
    SelectedMovies sm
WHERE 
    sm.production_companies IS NOT NULL
ORDER BY 
    sm.production_year DESC, sm.title;

This query combines several advanced SQL constructs:

1. **Common Table Expressions (CTEs)** for hierarchical queries (`MovieHierarchy`), lead actor ranking (`RankedCast`), and aggregation (`SelectedMovies`).
2. **Recursive CTE** to explore linked movies based on their relationships.
3. **Window functions** to rank actors and movies based on production year.
4. **Outer joins** to include movies without leading actors or production companies.
5. **CASE expressions** to categorize movies based on rank.
6. **Group by** aggregates to count production companies for each movie.
7. **Complicated predicates** to filter the results for movies released after 2000.
