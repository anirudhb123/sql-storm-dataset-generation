WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS rank
    FROM 
        aka_name a
    JOIN 
        aka_title t ON a.person_id = t.id
    WHERE 
        t.production_year > 2000
),
GenreKeywordMatches AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(*) > 1
),
TopRatedMovies AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(CASE WHEN pi.info_type_id = 1 THEN 1 ELSE 0 END) AS has_award_rating
    FROM 
        cast_info c
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id
    WHERE 
        pi.info_type_id IS NOT NULL
    GROUP BY 
        c.movie_id
    ORDER BY 
        cast_count DESC
    LIMIT 10
)
SELECT 
    RT.aka_name,
    RT.movie_title,
    RT.production_year,
    GKM.keyword,
    T.cast_count,
    T.has_award_rating
FROM 
    RankedTitles RT
JOIN 
    GenreKeywordMatches GKM ON RT.aka_id = GKM.movie_id
JOIN 
    TopRatedMovies T ON RT.production_year = T.movie_id
WHERE 
    RT.rank = 1
ORDER BY 
    RT.production_year DESC, T.cast_count DESC;
