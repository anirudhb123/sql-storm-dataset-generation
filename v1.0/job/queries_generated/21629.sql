WITH RecursiveCTE AS (
    SELECT 
        c.person_id,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    WHERE 
        c.nr_order IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        COALESCE(k.keyword, 'No Keyword') AS keyword
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
),
AggregateInfo AS (
    SELECT 
        p.person_id,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        SUM(CASE WHEN r.role IN ('Director', 'Producer') THEN 1 ELSE 0 END) AS num_director_producer_roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        person_info p ON c.person_id = p.person_id
    GROUP BY 
        p.person_id
),
TopMovies AS (
    SELECT 
        fm.movie_id,
        fm.title,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        ROW_NUMBER() OVER (ORDER BY fm.production_year DESC) AS year_rank
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        cast_info ci ON fm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        fm.movie_id, fm.title
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    COALESCE(a.total_movies, 0) AS total_movies_by_actor,
    TOP_MOV.actor_names,
    (CASE 
        WHEN f.year_rank <= 10 THEN 'Top 10 Movies' 
        ELSE 'Other Movies' 
     END) AS category
FROM 
    FilteredMovies f
LEFT JOIN 
    AggregateInfo a ON f.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = a.person_id)
LEFT JOIN 
    TopMovies TOP_MOV ON f.movie_id = TOP_MOV.movie_id
WHERE 
    (f.kind_id IS NOT NULL) AND 
    (f.production_year IS NOT NULL OR f.keyword IS NULL)
ORDER BY 
    f.production_year DESC, 
    total_movies_by_actor DESC;
