
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieRankings AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        keywords, 
        cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, production_year DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    m.title,
    m.production_year,
    m.cast_count,
    m.keywords,
    COALESCE(p.info, 'No information available') AS person_info
FROM 
    MovieRankings m
LEFT JOIN (
    SELECT 
        p.person_id,
        LISTAGG(pi.info, ', ') WITHIN GROUP (ORDER BY pi.info) AS info
    FROM 
        person_info pi
    JOIN 
        aka_name p ON pi.person_id = p.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
    GROUP BY 
        p.person_id
) p ON p.person_id IN (
    SELECT person_id 
    FROM cast_info ci 
    WHERE ci.movie_id = m.movie_id
)
WHERE 
    m.rank <= 10
ORDER BY 
    m.cast_count DESC;
