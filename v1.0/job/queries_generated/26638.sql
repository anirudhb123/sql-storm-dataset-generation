WITH RankedMovies AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
), 
MovieRankings AS (
    SELECT 
        title_id,
        title,
        production_year,
        cast_count,
        actor_names,
        keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank_by_cast
    FROM 
        RankedMovies
)
SELECT 
    mr.title_id,
    mr.title,
    mr.production_year,
    mr.cast_count,
    mr.actor_names,
    mr.keywords,
    mr.rank_by_cast
FROM 
    MovieRankings mr
WHERE 
    mr.rank_by_cast <= 10
ORDER BY 
    mr.rank_by_cast;
