WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
ActorMovies AS (
    SELECT 
        c.person_id, 
        c.movie_id, 
        a.name AS actor_name, 
        COUNT(*) OVER (PARTITION BY c.person_id) AS total_movies
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.note IS NULL
), 
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        k.keyword,
        COUNT(*) OVER (PARTITION BY m.id) AS keyword_count
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
), 
FinalResults AS (
    SELECT 
        a.actor_name,
        tt.title, 
        tt.production_year,
        mk.keyword,
        CASE 
            WHEN mk.keyword_count > 2 THEN 'High'
            WHEN mk.keyword_count = 2 THEN 'Medium'
            ELSE 'Low'
        END AS keyword_density
    FROM 
        ActorMovies a
    LEFT JOIN 
        RankedTitles tt ON a.movie_id = tt.id AND tt.rank <= 3
    LEFT JOIN 
        MoviesWithKeywords mk ON a.movie_id = mk.movie_id
    WHERE 
        mk.keyword IS NOT NULL 
        OR tt.production_year IS NULL
)
SELECT 
    f.actor_name,
    f.title,
    f.production_year,
    COALESCE(f.keyword, 'No Keyword') AS movie_keyword,
    f.keyword_density,
    CASE
        WHEN f.production_year < 1990 THEN 'Classic'
        WHEN f.production_year BETWEEN 1990 AND 2000 THEN '90s Classic'
        ELSE 'Modern'
    END AS era,
    (SELECT COUNT(DISTINCT mv.id) 
     FROM aka_title mv 
     WHERE mv.production_year = f.production_year) AS same_year_count
FROM 
    FinalResults f
WHERE 
    f.keyword IS NOT NULL
ORDER BY 
    f.production_year DESC, f.actor_name;
