WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year > 2000 
        AND EXISTS (
            SELECT 1
            FROM movie_info mi 
            WHERE mi.movie_id = m.id 
            AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
        )
    GROUP BY 
        m.id, m.title, m.production_year, mk.keyword
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        actor_count,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        FilteredMovies
)
SELECT 
    t.title,
    t.production_year,
    t.keyword,
    t.actor_count,
    a.aka_name
FROM 
    TopMovies t
LEFT JOIN 
    RankedTitles a ON t.movie_id = a.aka_id
WHERE 
    t.rank <= 10
ORDER BY 
    t.production_year DESC, 
    t.actor_count DESC;
