
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title at
    JOIN 
        cast_info c ON at.id = c.movie_id
    GROUP BY 
        at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank_per_year <= 5
),
MovieKeywords AS (
    SELECT 
        m.title,
        k.keyword
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = m.title AND production_year = m.production_year LIMIT 1)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
GenreCounts AS (
    SELECT 
        at.title,
        COUNT(mi.id) AS genre_count
    FROM 
        aka_title at
    LEFT JOIN 
        movie_info mi ON at.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info = 'Genre' 
    GROUP BY 
        at.title
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    COALESCE(g.genre_count, 0) AS genre_count
FROM 
    TopMovies m
LEFT JOIN (
    SELECT 
        title,
        LISTAGG(keyword, ', ') WITHIN GROUP (ORDER BY keyword) AS keywords
    FROM 
        MovieKeywords
    GROUP BY 
        title
) k ON m.title = k.title
LEFT JOIN 
    GenreCounts g ON m.title = g.title
WHERE 
    m.actor_count > 5
ORDER BY 
    m.production_year DESC, m.actor_count DESC;
