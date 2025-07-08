
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names,
        t.kind AS genre,
        k.keyword AS keywords
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        kind_type t ON a.kind_id = t.id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, t.kind, k.keyword
),
MovieRanking AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        cast_names,
        genre,
        keywords,
        RANK() OVER (PARTITION BY genre ORDER BY total_cast DESC) AS rank_within_genre
    FROM 
        RankedMovies
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.total_cast,
    m.cast_names,
    m.genre,
    m.keywords,
    m.rank_within_genre
FROM 
    MovieRanking m
WHERE 
    rank_within_genre <= 5
ORDER BY 
    m.genre, m.rank_within_genre;
