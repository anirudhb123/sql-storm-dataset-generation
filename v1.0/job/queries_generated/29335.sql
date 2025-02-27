WITH RankedMovies AS (
    SELECT 
        ak.name AS actor_name,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        COUNT(ci.person_id) AS total_cast_members,
        row_number() OVER (PARTITION BY m.id ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.id
    GROUP BY 
        ak.name, m.title, m.production_year, m.kind_id
),
HighlightedMovies AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        kind_id,
        total_cast_members,
        CASE 
            WHEN total_cast_members > 5 THEN 'Group Movie' 
            ELSE 'Solo Movie' 
        END AS movie_category
    FROM 
        RankedMovies
    WHERE 
        rn = 1
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        k.keyword,
        k.phonetic_code
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON k.id = mk.keyword_id
),
FinalResults AS (
    SELECT 
        hm.actor_name,
        hm.movie_title,
        hm.production_year,
        hm.movie_category,
        STRING_AGG(mk.keyword, ', ') AS associated_keywords
    FROM 
        HighlightedMovies hm
    LEFT JOIN 
        MovieKeywords mk ON hm.movie_title = mk.movie_id
    GROUP BY 
        hm.actor_name, hm.movie_title, hm.production_year, hm.movie_category
)

SELECT 
    fr.actor_name,
    fr.movie_title,
    fr.production_year,
    fr.movie_category,
    fr.associated_keywords
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, fr.actor_name;
