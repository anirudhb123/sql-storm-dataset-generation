WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
AkaData AS (
    SELECT 
        ak.person_id,
        ak.name,
        ak.imdb_index,
        t.title AS movie_title,
        t.production_year,
        t.kind_id
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        RankedMovies t ON ci.movie_id = t.movie_id
    WHERE 
        ak.name IS NOT NULL
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_total
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
FinalResults AS (
    SELECT 
        a.person_id,
        a.name,
        a.movie_title,
        a.production_year,
        kc.keyword_total,
        kt.kind AS movie_kind,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY a.production_year DESC) AS person_movie_rank
    FROM 
        AkaData a
    LEFT JOIN 
        KeywordCount kc ON a.movie_id = kc.movie_id
    LEFT JOIN 
        kind_type kt ON a.kind_id = kt.id
    WHERE 
        kc.keyword_total > 0
)
SELECT 
    fr.person_id,
    fr.name,
    fr.movie_title,
    fr.production_year,
    fr.keyword_total,
    fr.movie_kind
FROM 
    FinalResults fr
WHERE 
    fr.person_movie_rank <= 5
ORDER BY 
    fr.production_year DESC, 
    fr.keyword_total DESC;
