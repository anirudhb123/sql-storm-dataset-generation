
WITH RankedTitles AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.nr_order,
        ROW_NUMBER() OVER(PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank,
        t.id AS movie_id  -- Added to allow joining later
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
CompleteMovieInfo AS (
    SELECT 
        r.movie_title,
        r.production_year,
        r.actor_name,
        r.actor_rank,
        mk.keywords
    FROM 
        RankedTitles r
    LEFT JOIN 
        MovieKeywords mk ON r.movie_id = mk.movie_id
)
SELECT 
    cmi.movie_title,
    cmi.production_year,
    cmi.actor_name,
    cmi.actor_rank,
    cmi.keywords
FROM 
    CompleteMovieInfo cmi
WHERE 
    cmi.actor_rank <= 3
ORDER BY 
    cmi.production_year, cmi.actor_rank;
